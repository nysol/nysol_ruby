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
// kgshare.cpp 構成比計算クラス
// =============================================================================
#include <cstdio>
#include <vector>
#include <kgshare.h>
#include <kgError.h>
#include <kgVal.h>
#include <kgConfig.h>

using namespace std;
using namespace kglib;
using namespace kgmod;

// -----------------------------------------------------------------------------
// コンストラクタ(モジュール名，バージョン登録)
// -----------------------------------------------------------------------------
kgShare::kgShare(void)
{
	_name    = "kgshare";
	_version = "###VERSION###";
	_paralist = "f=,i=,o=,k=,-q";
	_paraflg = kgArgs::ALLPARAM;

	#include <help/en/kgshareHelp.h>
	_titleL = _title;
	_docL   = _doc;
	#ifdef JPN_FORMAT
		#include <help/jp/kgshareHelp.h>
	#endif


}
// -----------------------------------------------------------------------------
// 入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgShare::setArgsMain(void)
{
	_iFile.read_header();
  _oFile.setPrecision(_precision);

	// f= 項目引数のセット
	vector< vector<kgstr_t> > vvs = _args.toStringVecVec("f=",':',2,true);

	// k= 項目引数のセット
	vector<kgstr_t> vs = _args.toStringVector("k=",false);

	bool seqflg = _args.toBool("-q");
	if(_nfn_i) { seqflg = true; }
	if(!seqflg && !vs.empty()){ sortingRun(&_iFile,vs);}

	_fField.set(vvs, &_iFile, _fldByNum);
	_kField.set(vs,  &_iFile, _fldByNum);

}

// -----------------------------------------------------------------------------
// 入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgShare::setArgs(void)
{
	// パラメータチェック
	_args.paramcheck(_paralist,_paraflg);

	// 入出力ファイルオープン
	_iFile.open(_args.toString("i=",false), _env,_nfn_i);
  _oFile.open(_args.toString("o=",false), _env,_nfn_o);

	setArgsMain();
}

// -----------------------------------------------------------------------------
// 入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgShare::setArgs(int inum,int *i_p,int onum, int* o_p)
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
int kgShare::runMain(void) try 
{
	// 入力ファイルにkey項目番号をセットする．
	_iFile.setKey(_kField.getNum());

	// 項目名の出力
  _oFile.writeFldName(_iFile,_fField, true);

	// 集計用変数領域確保＆初期化
	vector<double> sum(_fField.size() ,0);
	vector<kgVal>  share(_fField.size() ,kgVal('N'));
	for(vector<kgVal>::size_type i=0; i<share.size(); i++){ share[i].r(0);}

	while(_iFile.blkset()!=EOF){
		//キー単位集計
		while(  EOF != _iFile.blkread() ){
			for(std::size_t i=0; i<_fField.size(); i++){
				char* str=_iFile.getBlkVal(_fField.num(i));
				if(*str){ sum[i] += atof(str);}
				else { 
					if(_assertNullIN){ _existNullIN  = true;} 
				}
			}
		}
		//シェア計算
		_iFile.seekBlkTop();
		while(  EOF != _iFile.blkread() ){
			_oFile.writeFld(_iFile.fldSize(),_iFile.getBlkFld(),false);
			for(std::size_t i=0; i<_fField.size(); i++){
				char* str=_iFile.getBlkVal(_fField.num(i));
				if(!*str||sum[i]==0){
					if(_assertNullOUT){ _existNullOUT = true; }
					if(i<_fField.size()-1) _oFile.writeDlm();
					else                   _oFile.writeEol();			
				}
				else{
					double res= atof(_iFile.getBlkVal(_fField.num(i))) /sum.at(i);
					if(i<_fField.size()-1) _oFile.writeDbl(res,false);
					else                   _oFile.writeDbl(res,true);			
				}
			}
		}
		//初期化
		for(std::size_t i=0; i<_fField.size(); i++){ sum[i]=0; }
	}

	//ASSERT keynull_CHECK
	if(_assertNullKEY) { _existNullKEY = _iFile.keynull(); }

	// 終了処理
	th_cancel();
	_iFile.close();
	_oFile.close();
	successEnd();
	return 0;

// 例外catcher
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
int kgShare::run(void) 
{
	setArgs();
	return runMain();
}

int kgShare::run(int inum,int *i_p,int onum, int* o_p)
{
	setArgs(inum, i_p, onum,o_p);
	return runMain();
}
