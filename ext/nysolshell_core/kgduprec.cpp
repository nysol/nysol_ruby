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
// kgduprec.cpp 行の複製
// =============================================================================
#include <cstdio>
#include <kgduprec.h>
#include <kgError.h>
#include <kgConfig.h>

using namespace std;
using namespace kglib;
using namespace kgmod;

// -----------------------------------------------------------------------------
// コンストラクタ(モジュール名，バージョン登録,パラメータ)
// -----------------------------------------------------------------------------
kgDuprec::kgDuprec(void)
{
	_name    = "kgduprec";
	_version = "###VERSION###";

	_paralist = "f=,i=,o=,n=";
	_paraflg = kgArgs::COMMON|kgArgs::IODIFF|kgArgs::NULL_IN;


	#include <help/en/kgduprecHelp.h>
	_titleL = _title;
	_docL   = _doc;
	#ifdef JPN_FORMAT
		#include <help/jp/kgduprecHelp.h>
	#endif


}
// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgDuprec::setArgsMain(void)
{
	_iFile.read_header();
	
	// f= 項目引数のセット
	kgstr_t fs = _args.toString("f=",false);
	if(!fs.empty()){ _fField.set(fs,  &_iFile,_fldByNum); }

	// n=のセット
	kgstr_t s=_args.toString("n=",false);
	_num = 0;
	if(!s.empty()){
		_num =atoi(s.c_str());
		if(_num <= 0){ throw kgError("n= takes interger >=1"); }
	}
	if((_num==0 && fs.empty())||( _num!=0 && !fs.empty())){
		throw kgError("Either n= or f= must be specified.");
	}
}

// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgDuprec::setArgs(void)
{
	// パラメータチェック
	_args.paramcheck(_paralist,_paraflg);

	// 入出力ファイルオープン
	_iFile.open(_args.toString("i=",false), _env, _nfn_i);
	_oFile.open(_args.toString("o=",false), _env, _nfn_o);

	setArgsMain();

}

// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgDuprec::setArgs(int inum,int *i_p,int onum, int* o_p)
{
	// パラメータチェック
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
int kgDuprec::runMain(void) try 
{

	//項目名出力
	_oFile.writeFldName(_iFile);

	int gyo = _num;
	// 行数を取得してデータ出力
	while( EOF != _iFile.read() ){
		if (_num==0) {
			if(*_iFile.getVal(_fField.num(0))=='\0' && _assertNullIN ) { _existNullIN  = true;}
			gyo = atoi(_iFile.getVal(_fField.num(0)));
		}
		for(int i=0;i<gyo;i++){
			_oFile.writeFld(_iFile.fldSize(),_iFile.getFld());
		}
	}
	// 終了処理
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
int kgDuprec::run(void) 
{
	setArgs();
	return runMain();
}

int kgDuprec::run(int inum,int *i_p,int onum, int* o_p)
{
	setArgs(inum, i_p, onum,o_p);
	return runMain();
}


