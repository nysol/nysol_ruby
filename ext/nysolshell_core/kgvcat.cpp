/* ////////// LICENSE INFO ////////////////////

 * Copyright (C) 2013 by NYSOL CORPORATION
 *
 * Unless you have received this program directly from NYSOL pursuant
 * to the terms of a commercial license agreement with NYSOL, then
 * this program is licensed to you under the terms of the GNU Affero General
 * Public License (AGPL) as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF 
 * NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Please refer to the AGPL (http://www.gnu.org/licenses/agpl-3.0.txt)
 * for more details.

 ////////// LICENSE INFO ////////////////////*/
// =============================================================================
// kgvcat.cpp ベクトルの併合クラス
// =============================================================================
#include <cstdio>
#include <sstream>
#include <string>
#include <vector>
#include <kgConfig.h>
#include <kgvcat.h>
#include <kgCSVout.h>
#include <kgError.h>
#include <kgMethod.h>

using namespace std;
using namespace kglib;
using namespace kgmod;

// -----------------------------------------------------------------------------
// コンストラクタ(モジュール名，バージョン登録)
// -----------------------------------------------------------------------------
kgVcat::kgVcat(void)
{
	_name    = "kgvcat";
	_version = "###VERSION###";

	_paralist = "i=,o=,vf=,delim=,a=,-A";
	_paraflg = kgArgs::COMMON|kgArgs::IODIFF|kgArgs::NULL_IN|kgArgs::NULL_OUT;

	#include <help/en/kgvcatHelp.h>
	_titleL = _title;
	_docL   = _doc;
	#ifdef JPN_FORMAT
		#include <help/jp/kgvcatHelp.h>
	#endif

}
// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgVcat::setArgsMain(void)
{
	_iFile.read_header();

	// vf= 項目引数のセット
	vector<kgstr_t>  vs = _args.toStringVector("vf=",true);
	_vfField.set(vs, &_iFile,_fldByNum);

	// a = 新規項目名
	_newname = _args.toString("a=",true);

	// 追加項目フラグ
	_add  = _args.toBool("-A");
	
	kgstr_t s_d = _args.toString("delim=",false);
	if(s_d.empty()){	
		_delim=' ';
	}else if(s_d.size()!=1){
		ostringstream ss;
		ss << "delim= takes 1 byte charactor (" << s_d << ")";
		throw kgError(ss.str());
	}else{
		_delim=*(s_d.c_str());
	}
}

// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgVcat::setArgs(void)
{
	_args.paramcheck(_paralist,_paraflg);

	// 入出力ファイルオープン
	_iFile.open(_args.toString("i=",false),_env,_nfn_i);
	_oFile.open(_args.toString("o=",false),_env,_nfn_o);

	setArgsMain();

}
// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgVcat::setArgs(int inum,int *i_p,int onum ,int *o_p)
{
	_args.paramcheck(_paralist,_paraflg);

	if(inum>1 || onum>1){ throw kgError("no match IO");}

	if(inum==1 && *i_p>0){ _iFile.popen(*i_p, _env,_nfn_i); }
	else     { _iFile.open(_args.toString("i=",false), _env,_nfn_i); }

	if(onum==1 && *o_p>0){ _oFile.popen(*o_p, _env,_nfn_o); }
	else     { _oFile.open(_args.toString("o=",false), _env,_nfn_o);}

	setArgsMain();
}
// -----------------------------------------------------------------------------
// 実行
// -----------------------------------------------------------------------------
int kgVcat::runMain(void) try 
{
	// 項目名出力 -Aの指定がない場合にはvf=で指定した項目は出力しない
	if(!_nfn_o){
		vector<kgstr_t> outfld;
		for(size_t i=0; i<_iFile.fldSize(); i++){
			if( _vfField.flg(i)==-1 || _add) {
				outfld.push_back(_iFile.fldName(i,true));
			}
		}
		outfld.push_back(_newname);
		_oFile.writeFldNameCHK(outfld);
	}

	//文字列生成用領域
	char delimchar[2];
	delimchar[0] =_delim;
	delimchar[1] ='\0';
	char buf[KG_MAX_STR_LEN];

	while(EOF != _iFile.read() ){
		*buf = '\0'; 
		int len=0;

		//-Aの指定がない場合にはvf=で指定した項目は出力しない
		for(size_t i=0; i<_iFile.fldSize(); i++){
			if( _vfField.flg(i)==-1||_add){
				_oFile.writeStr( _iFile.getVal(i), false);
			}
		}

		for(size_t i=0; i<_vfField.size(); i++){
			char* str=_iFile.getVal(_vfField.num(i));
			if(*str=='\0'){ 
				if(_assertNullIN) { _existNullIN  = true;}
				continue;
			}
			len += ( strlen(str) + 1);
			if(len>=KG_MAX_STR_LEN){ throw kgError("exceed max record length");}
			if(*buf != '\0') strcat( buf,delimchar );
			strcat( buf,str );
		}
		if(_assertNullOUT && *buf=='\0'){ _existNullOUT = true;}
		_oFile.writeStr(buf,true);

	}

	// 終了処理(メッセージ出力,thread pipe終了通知)
	_iFile.close();
	_oFile.close();
	successEnd();
	return 0;

}catch(kgOPipeBreakError& err){
	// 終了処理
	_iFile.close();
	successEnd();
	return 0;
}catch(kgError& err){
	errorEnd(err);
	return 1;
}catch (const exception& e) {
	kgError err(e.what());
	errorEnd(err);
	return 1;
}catch(char * er){
	kgError err(er);
	errorEnd(err);
	return 1;
}catch(...){
	kgError err("unknown error" );
	errorEnd(err);
	return 1;
}

// -----------------------------------------------------------------------------
// 実行 
// -----------------------------------------------------------------------------
int kgVcat::run(void) 
{
	setArgs();
	return runMain();
}

int kgVcat::run(int inum,int *i_p,int onum, int* o_p)
{
	setArgs(inum, i_p, onum,o_p);
	return runMain();
}
