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
// ============================================================================
// kgarff2csv.cpp : wekaのデータフォーマット→CSV変換
// ============================================================================
#pragma once
//#include <cstdio>
#include <kgmod.h>
#include <kgArgFld.h>
#include <kgCSV.h>
#include <kgCSVout.h>

using namespace kglib;

namespace kgmod  ////////////////////////////////////////////// start namespace
{
class kgArff2csv : public kgMod 
{
	// 引数
	kgCSVrecSimple _iFile;   // i=
	kgCSVout _oFile;   // o=
	// FILE *_iF;テスト
	
	// 引数セット
	void setArgs(void);
	void setArgs(int inum,int *i,int onum, int* o);

	int runMain(void);

	void arff2data(char* recdata,char* setdata);
	bool sameStr(const char* rec, const char* str);

	void runErrEnd(void){
		_iFile.close();
		_oFile.close();
	}

public:
	// コンストラクタ
	kgArff2csv(void);
	~kgArff2csv(void){}

	// 処理行数取得メソッド
	//size_t iRecNo(void) const { return _iFile.recNo(); }
	size_t oRecNo(void) const { return _oFile.recNo(); }

	//実行関数メソッド
	int run(void);
	int run(int inum,int *i_p,int onum, int* o_p ,string & str);


};

}

