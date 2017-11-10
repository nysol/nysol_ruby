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
// kgfldname.h 項目名の変更
// =============================================================================
#pragma once
#include <vector>
#include <kgConfig.h>
#include <kgmod.h>
#include <kgArgFld.h>
#include <kgCSV.h>
#include <kgCSVout.h>

using namespace kglib;

namespace kgmod { ////////////////////////////////////////////// start namespace

class kgFldname : public kgMod 
{
	// 引数
	kgCSVrec _iFile;   // i=
	kgCSVout _oFile;   // o=
	kgArgFld _fField;  // f=
	vector<kgstr_t> newFldName_; //ヘッダがセットされる.
	bool _rmsinfo;
	// 引数セット
  void setArgs(void);
	void setArgs(int inum,int *i,int onum, int* o);
	void setArgsMain(void);	

	int runMain(void);
public:
  // コンストラクタ
	kgFldname(void);
	~kgFldname(void){}

	//実行メソッド
	int run(void);
	int run(int inum,int *i,int onum, int* o);

	// 処理行数取得メソッド
	size_t iRecNo(void) const { return _iFile.recNo(); }
	size_t oRecNo(void) const { return _oFile.recNo(); }

};

}
