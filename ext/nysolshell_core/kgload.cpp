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
// kgLoad.cpp 行の複製
// =============================================================================
#include <cstdio>
#include <kgload.h>
#include <kgError.h>
#include <kgConfig.h>

using namespace std;
using namespace kglib;
using namespace kgmod;

static VALUE str2rbstr(char *ptr)
{
	// rb_external_str_new_cstrが定義されているばそちらを使う
	#if defined(rb_external_str_new_cstr)
		return rb_external_str_new_cstr(ptr);
	#else
		return rb_str_new2(ptr);
	#endif


}

// -----------------------------------------------------------------------------
// コンストラクタ(モジュール名，バージョン登録,パラメータ)
// -----------------------------------------------------------------------------
kgLoad::kgLoad(void)
{
	_name    = "kgload";
	_version = "###VERSION###";

	_paralist = "i=,o=";
	_paraflg = kgArgs::COMMON|kgArgs::IODIFF;

	_titleL = _title = "";
	
}
// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgLoad::setArgs(void)
{
	// パラメータチェック
	_args.paramcheck("i=,o=",kgArgs::COMMON|kgArgs::IODIFF);

	// 入出力ファイルオープン
	_iFile.open(_args.toString("i=",false), _env, _nfn_i);
	_oFile.open(_args.toString("o=",false), _env, _nfn_o);

	_iFile.read_header();
	
}

// -----------------------------------------------------------------------------
// パラメータセット＆入出力ファイルオープン
// -----------------------------------------------------------------------------
void kgLoad::setArgs(int inum,int *i_p,int onum,int* o_p)
{
	// パラメータチェック
	_args.paramcheck("i=,o=",kgArgs::COMMON|kgArgs::IODIFF);

	if(inum>1 || onum>1){
		throw kgError("no match IO");
	}

	// 入出力ファイルオープン
	if(inum==1 && *i_p > 0){ _iFile.popen(*i_p, _env,_nfn_i); }
	else     { _iFile.open(_args.toString("i=",true), _env,_nfn_i); }

	if(onum==1 && *o_p > 0){ _oFile.popen(*o_p, _env,_nfn_o); }
	else     { _oFile.open(_args.toString("o=",true), _env,_nfn_o);}

	_iFile.read_header();
	
}

// -----------------------------------------------------------------------------
// 実行
// -----------------------------------------------------------------------------
int kgLoad::run(void)
{
	try {
		size_t fcnt=0;
		// パラメータセット＆入出力ファイルオープン
		setArgs();

		// headerがあるとき
		if(!_nfn_i){
			vector<string> head;
			if(EOF != _iFile.read()){
				char * data = _iFile.getRec();
				string hdata = data;
				head = splitToken(hdata,',');
				fcnt = head.size();
			}
			// headerを出力するとき
			if(!_nfn_o){ _oFile.writeFldName(head);}
		}
		// 行数を取得してデータ出力
		while( EOF != _iFile.read() ){
			_oFile.writeRec(_iFile.getRec());
		}
		// 終了処理
		_iFile.close();
		_oFile.close();
		successEnd();
		return 0;
	}catch(kgError& err){
		_iFile.close();
		_oFile.close();
		errorEnd(err);
		return 1;
	}catch (const exception& e) {
		_iFile.close();
		_oFile.close();
		kgError err(e.what());
		errorEnd(err);
		return 1;
	}catch(char * er){
		_iFile.close();
		_oFile.close();
		kgError err(er);
		errorEnd(err);
		return 1;
	}catch(...){
		_iFile.close();
		_oFile.close();
		kgError err("unknown error" );
		errorEnd(err);
		return 1;
	}
	return 1;
}

// -----------------------------------------------------------------------------
// 実行
// -----------------------------------------------------------------------------
int kgLoad::run(int inum,int *i_p,int onum, int* o_p,string &msg)
{
	try {
		size_t fcnt=0;
		// パラメータセット＆入出力ファイルオープン
		setArgs(inum, i_p,onum, o_p);
		// headerがあるとき
		if(!_nfn_i){
			vector<string> head;
			if(EOF != _iFile.read()){
				char * data = _iFile.getRec();
				string hdata = data;
				head = splitToken(hdata,',');
				fcnt = head.size();
			}
			// headerを出力するとき
			if(!_nfn_o){ _oFile.writeFldName(head);}
		}
		// 行数を取得してデータ出力
		while( EOF != _iFile.read() ){
			_oFile.writeRec(_iFile.getRec());
		}
		// 終了処理
		_iFile.close();
		_oFile.close();
		msg.append(successEndMsg());
		return 0;

	}catch(kgError& err){
		_iFile.close();
		_oFile.close();
		msg.append(errorEndMsg(err));

	}catch (const exception& e) {
		_iFile.close();
		_oFile.close();
		kgError err(e.what());
		msg.append(errorEndMsg(err));

	}catch(char * er){
		_iFile.close();
		_oFile.close();
		kgError err(er);
		msg.append(errorEndMsg(err));

	}catch(...){
		_iFile.close();
		_oFile.close();
		kgError err("unknown error" );
		msg.append(errorEndMsg(err));

	}
	return 1;
}
// -----------------------------------------------------------------------------
// 実行
// -----------------------------------------------------------------------------
int kgLoad::run(VALUE i_p,int onum,int *o_p,string &msg)
{
	try {
		// パラメータチェック
		_args.paramcheck("o=",kgArgs::COMMON|kgArgs::IODIFF);

		if(onum>1){
			throw kgError("no match IO");
		}
		if(onum==1 && *o_p > 0){ _oFile.popen(*o_p, _env,_nfn_o); }
		else     { _oFile.open(_args.toString("o=",true), _env,_nfn_o);}

		if(TYPE(i_p)==T_ARRAY){ 
			size_t max = RARRAY_LEN(i_p);
			size_t fldsize = 0;
			size_t nowlin = 0;
			vector<string> headdata;
			if ( max > 0 ){
				// headerがあるとき
				if(!_nfn_i){
					VALUE head = rb_ary_entry(i_p, nowlin);
					fldsize = RARRAY_LEN(head); 
					for(size_t i=0 ; i<fldsize;i++){
						headdata.push_back(RSTRING_PTR(rb_ary_entry(head,i)));
					}		
					nowlin++;
				}
				else{
					fldsize = RARRAY_LEN(rb_ary_entry(i_p, nowlin));
				}
				// headerを出力するとき
				if(!_nfn_o){ _oFile.writeFldName(headdata);}
				// 行数を取得してデータ出力
				char ** vals = new char*[fldsize];
				while( nowlin < max ){
					VALUE ddata = rb_ary_entry(i_p, nowlin);
					if( fldsize != RARRAY_LEN(ddata) ){
						kgError err("unmatch fld size" );	
					}
					for(size_t i=0 ; i<fldsize;i++){
						vals[i] = RSTRING_PTR(rb_ary_entry(ddata,i));
					}
					_oFile.writeFld(fldsize,vals);
					nowlin++;
				}
				delete[] vals;
			}
		}else{
			throw kgError("not python Array");
		}
		_oFile.close();
		msg.append(successEndMsg());
		return 0;

	}catch(kgError& err){
		_oFile.close();
		msg.append(errorEndMsg(err));

	}catch (const exception& e) {
		_oFile.close();
		kgError err(e.what());
		msg.append(errorEndMsg(err));

	}catch(char * er){
		_oFile.close();
		kgError err(er);
		msg.append(errorEndMsg(err));
	}catch(...){
		_oFile.close();
		kgError err("unknown error" );
		msg.append(errorEndMsg(err));
	}
	return 1;

}
// -----------------------------------------------------------------------------
// 実行
// -----------------------------------------------------------------------------
int kgLoad::run(int inum,int *i_p,VALUE o_p,pthread_mutex_t *mtx,string &msg) 
{
	try {
		// パラメータチェック
		_args.paramcheck("i=",kgArgs::COMMON|kgArgs::IODIFF);
		if(inum>1){ throw kgError("no match IO"); }

		kgCSVfld rls;

		// 入出力ファイルオープン
		if(inum==1 && *i_p > 0){ rls.popen(*i_p, _env,_nfn_i); }
		else     { rls.open(_args.toString("i=",true), _env,_nfn_i); }
		rls.read_header();

		if(TYPE(o_p)==T_ARRAY){ 
			while( EOF != rls.read() ){
				pthread_mutex_lock(mtx);
				{
					VALUE tlist = rb_ary_new2(rls.fldSize());
					for(size_t j=0 ;j<rls.fldSize();j++){
						rb_ary_store( tlist,j,str2rbstr(rls.getVal(j)));
					}
					rb_ary_push(o_p,tlist);
				}
				pthread_mutex_unlock(mtx);
			}
			rls.close();
		}
		else{
			throw kgError("not ruby Array");
		}
		msg.append(successEndMsg());
		return 0;

	}
	catch(kgError& err){
		pthread_mutex_unlock(mtx);
		msg.append(errorEndMsg(err));

	}catch (const exception& e) {
		pthread_mutex_unlock(mtx);
		kgError err(e.what());
		msg.append(errorEndMsg(err));

	}catch(char * er){
		pthread_mutex_unlock(mtx);
		kgError err(er);
		msg.append(errorEndMsg(err));

	}catch(...){
		pthread_mutex_unlock(mtx);
		kgError err("unknown error" );
		msg.append(errorEndMsg(err));

	}
	return 1;
}
