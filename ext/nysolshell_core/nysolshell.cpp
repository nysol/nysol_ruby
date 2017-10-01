// helloWrapper.c
#include <ruby.h>
#include <kgEnv.h>
#include <kgMethod.h>
#include <kgCSV.h>
#include <kgshell.h>

using namespace kgmod;
using namespace kglib;


extern "C" {
	void Init_nysolshell_core(void);
}

static VALUE str2rbstr(string ptr)
{
	// rb_external_str_new_cstrが定義されているばそちらを使う
	#if defined(rb_external_str_new_cstr)
		return rb_external_str_new_cstr(ptr.c_str());
	#else
		return rb_str_new2(ptr.c_str());
	#endif
	
}

int run_sub(VALUE tlist,
	vector< cmdCapselST >& cmdcap,
	vector< vector<int> > & p_list, // i,o,tp(0:i=,1:m=)
	int lcnt
){
	int pos = lcnt;

	int ipos = -1;
	int mpos = -1;

	cmdCapselST cmpcaplocal;
	cmpcaplocal.cmdname = RSTRING_PTR(rb_ary_entry(tlist, 0));

	// もとを文字に直さなくてもいいかも
	kgstr_t para_part = "";

	if(TYPE(rb_ary_entry(tlist, 1))==T_STRING){
		para_part = RSTRING_PTR(rb_ary_entry(tlist, 1));
	}
	cmpcaplocal.paralist=kglib::splitToken(para_part, ' ',true);

	VALUE ilink = rb_ary_entry(tlist, 2);
	VALUE mlink = rb_ary_entry(tlist, 3);

	if(TYPE(ilink)==T_STRING){
		cmpcaplocal.paralist.push_back( kgstr_t("i=")+ RSTRING_PTR(ilink) );
		cmdcap.push_back(cmpcaplocal);
	}
	else if(TYPE(ilink)==T_ARRAY){
		if(TYPE(rb_ary_entry(ilink, 0))==T_ARRAY){
			cmdcap.push_back(cmpcaplocal);
			cmdCapselST cmpcapmload;
			//list data mload追加
			ipos = lcnt+1;
			cmpcapmload.cmdname="mload";
			cmpcapmload.iobj=ilink;
			cmdcap.push_back(cmpcapmload);

			lcnt++;
			vector<int> pno_i;
			pno_i.push_back(pos-1);
			pno_i.push_back(ipos-1);
			pno_i.push_back(0);
			p_list.push_back(pno_i);
		}
		else{
			cmdcap.push_back(cmpcaplocal);
			ipos = lcnt+1;
			lcnt = run_sub(ilink,cmdcap,p_list,lcnt+1);

			vector<int> pno_i;
			pno_i.push_back(pos-1);
			pno_i.push_back(ipos-1);
			pno_i.push_back(0);
			p_list.push_back(pno_i);
		}
	}
	if(TYPE(mlink)==T_STRING){
		cmdcap[pos-1].paralist.push_back( kgstr_t("m=")+ RSTRING_PTR(mlink) );
	}
	else if(TYPE(mlink)==T_ARRAY){
		if(TYPE(rb_ary_entry(mlink, 0))==T_ARRAY){
			cmdCapselST cmpcapmload;
			//list data mload追加
			mpos = lcnt+1;
			cmpcapmload.cmdname="mload";
			cmpcapmload.iobj=mlink;
			cmdcap.push_back(cmpcapmload);

			lcnt++;
			vector<int> pno_o;
			pno_o.push_back(pos-1);
			pno_o.push_back(mpos-1);
			pno_o.push_back(1);
			p_list.push_back(pno_o);
		}
		else{
			mpos = lcnt+1;	
			lcnt = run_sub(mlink,cmdcap,p_list,lcnt+1);
			vector<int> pno_o;
			pno_o.push_back(pos-1);
			pno_o.push_back(mpos-1);
			pno_o.push_back(1);
			p_list.push_back(pno_o);
		}
	}
	if(ilink==Qnil &&mlink==Qnil ){
		cmdcap.push_back(cmpcaplocal);
	}
	return lcnt;
}


VALUE run(int argc, VALUE *argv, VALUE self)
{
	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);

	// 引数をopetionsにセット
	VALUE runlist1;
	VALUE runflg;
	rb_scan_args(argc, argv,"2",&runlist1,&runflg);
	bool tp = false ;
	if(TYPE(runflg)==T_TRUE){ tp = true; } 


	if(TYPE(runlist1)!=T_ARRAY){ 
		cerr << "error  " << endl;
		return Qnil;
	} 
	
	long len = RARRAY_LEN(runlist1);
	
	vector< vector<int> > p_list;
	vector< cmdCapselST > cmdCapsel;

	int  lsize = run_sub(runlist1,cmdCapsel,p_list,1);

	// debug
	//cerr <<  "------" << endl;
	//cerr <<  "lsize " << lsize << endl;
	//for(int i=0;i<cmdCapsel.size();i++){
	//	cerr << i << " " << cmdCapsel[i].cmdname << endl;
	//}
	//cerr <<  "------" << endl;
	//for(int i=0;i<p_list.size();i++){
	//	cerr << i << " i:" << p_list[i][0] << "<<o:" << p_list[i][1]<< endl;
	//}

	VALUE rlist=rb_ary_new();
	rmod->run(cmdCapsel,p_list,tp,rlist);

	if(tp){
		return rlist;
	}else{
		return Qnil;
	}	

}


// -----------------------------------------------------------------------------
// メモリ解放
// kgRubyModの領域開放(GC時にrubyにより実行される)(xxx_alloc()にて登録される)
// -----------------------------------------------------------------------------
void kgeachiter_free(kgCSVfld* rmod) try 
{
		if(rmod!=0) delete rmod;

}catch(...){
	rb_raise(rb_eRuntimeError,"Error at csvin_free()");
}

VALUE runP(VALUE self,VALUE runlist1,VALUE runflg)
{
	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);

	// 引数をopetionsにセット
	bool tp = false ;
	if(TYPE(runflg)==T_TRUE){ tp = true; } 


	if(TYPE(runlist1)!=T_ARRAY){ 
		cerr << "error  " << endl;
		return Qnil;
	} 
	
	long len = RARRAY_LEN(runlist1);
	
	vector< vector<int> > p_list;
	vector< cmdCapselST > cmdCapsel;

	int  lsize = run_sub(runlist1,cmdCapsel,p_list,1);

	// debug
	//cerr <<  "------" << endl;
	//cerr <<  "lsize " << lsize << endl;
	//for(int i=0;i<cmd_vv.size();i++){
	//	cerr << i << " " << cmd_vv[i] << endl;
	//}
	//cerr <<  "------" << endl;
	//for(int i=0;i<p_list.size();i++){
	//	cerr << i << " i:" << p_list[i][0] << "<<o:" << p_list[i][1]<< endl;
	//}

	VALUE rlist=rb_ary_new();
	kgCSVfld* rtn = rmod->runiter(cmdCapsel,p_list,tp,rlist);

	VALUE nrb=rb_define_module("NYSOLRUBY");
	VALUE nrcsvfld = rb_define_class_under(nrb,"KgcsvFLD",rb_cObject);

	VALUE object=Data_Wrap_Struct(nrcsvfld,0,0,rtn);

	
/*	cerr << "xxx1" << endl;
	int fcnt = rtn->fldSize();
	cerr << "xxx2" << endl;
	while( rtn->read() != EOF){
		cerr << "xxx3" << endl;
		VALUE rlistx=rb_ary_new();
		cerr << "xxx4" << endl;
		for(size_t j=0 ;j<fcnt;j++){
			rb_ary_push(rlistx,str2rbstr(rtn->getVal(j)));
		}
		cerr << "xxx5" << endl;
		rb_yield_values(1,rlistx);
		cerr << "xxx6" << endl;
	}
	delete rtn;
	return rtn
*/

//	VALUE object=Data_Wrap_Struct(klass,0,kgeachiter_free,rtn);
	return object;
//	return 0;



}
VALUE readline(VALUE self,VALUE args )
{
	kgCSVfld* csvin;
	Data_Get_Struct(args,kgCSVfld,csvin);

	if( csvin->read() == EOF){
		return Qnil;
	}
	int fcnt = csvin->fldSize();

	VALUE rlist=rb_ary_new();
	for(size_t j=0 ;j<fcnt;j++){
		rb_ary_push(rlist,str2rbstr(csvin->getVal(j)));
	}
	return rlist;

//	int fcnt = kcfld->fldSize();
//	PyObject* rlist = PyList_New(0);
//	for(size_t j=0 ;j<fcnt;j++){
//		PyList_Append(rlist,Py_BuildValue("s", kcfld->getVal(j)));
//	}
//	return rlist;


//	PyObject *csvin;
	//PyObject *list;
	//int tp;
//	if (!PyArg_ParseTuple(args, "O", &csvin)){
//    return Py_BuildValue("");
//  }

//	kgCSVfld *kcfld	= (kgCSVfld *)PyCapsule_GetPointer(csvin,"kgCSVfldP");

//	if( kcfld->read() == EOF){
//		return Py_BuildValue("");
//	}
//	int fcnt = kcfld->fldSize();
//	PyObject* rlist = PyList_New(0);
//	for(size_t j=0 ;j<fcnt;j++){
//		PyList_Append(rlist,Py_BuildValue("s", kcfld->getVal(j)));
//	}
//	return rlist;
	//return 1;
}

/*
void py_kgshell_free(PyObject *obj){
	kgshell *ksh	= (kgshell *)PyCapsule_GetPointer(obj,"kgshellP");
	delete ksh;
}
*/

VALUE getparams(VALUE self , VALUE cname ){

	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);

	if(TYPE(cname)!=T_STRING){ 
		cerr << "errerr " << endl;
		return Qnil;
	}

	VALUE rlist=rb_ary_new();
	rmod->getparams(RSTRING_PTR(cname),rlist);
	return rlist;

}

VALUE start(int argc, VALUE *argv, VALUE self){	

	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);
	VALUE runflg;
	rb_scan_args(argc, argv,"01",&runflg);
	if(runflg==Qfalse ){
		rmod->msgOff();
	}
	return self;
//	return PyCapsule_New(new kgshell,"kgshellP",py_kgshell_free);
	
}
/*
static PyMethodDef hellomethods[] = {
	{"init", reinterpret_cast<PyCFunction>(start), METH_VARARGS },
	{"run", reinterpret_cast<PyCFunction>(run), METH_VARARGS },
	{"runiter", reinterpret_cast<PyCFunction>(runP), METH_VARARGS },
	{"readline", reinterpret_cast<PyCFunction>(readline), METH_VARARGS },
	{"getparalist", reinterpret_cast<PyCFunction>(getparams), METH_VARARGS },
	{NULL},
};

void init_nysolshell_core(void)
{
	Py_InitModule("_nysolshell_core", hellomethods);
}

*/


// -----------------------------------------------------------------------------
// メモリ解放
// kgRubyModの領域開放(GC時にrubyにより実行される)(xxx_alloc()にて登録される)
// -----------------------------------------------------------------------------
void nrbCore_free(kgshell* rmod) try 
{
		if(rmod!=0) delete rmod;

}catch(...){
	rb_raise(rb_eRuntimeError,"Error at csvin_free()");
}

// -----------------------------------------------------------------------------
// インスタンス化される時のメモリ確保
// -----------------------------------------------------------------------------
VALUE nrbCore_alloc(VALUE klass) try 
{
	kgshell* rmod=new kgshell;
	VALUE object=Data_Wrap_Struct(klass,0,nrbCore_free,rmod);
	return object;

}catch(...){
	rb_raise(rb_eRuntimeError,"Error at csvin_alloc()");
}


void Init_nysolshell_core(void)
{
	VALUE nrb=rb_define_module("NYSOLRUBY");
	VALUE nrbCore = rb_define_class_under(nrb,"MshCore",rb_cObject);
	rb_define_alloc_func(nrbCore, nrbCore_alloc);
	rb_define_method(nrbCore,"initialize" , (VALUE (*)(...))start    ,-1);
	rb_define_method(nrbCore,"run"        , (VALUE (*)(...))run      ,-1);
	rb_define_method(nrbCore,"runiter"    , (VALUE (*)(...))runP     ,2);
	rb_define_method(nrbCore,"readline"   , (VALUE (*)(...))readline ,1);
	rb_define_method(nrbCore,"getparalist", (VALUE (*)(...))getparams,1);

	VALUE nrcsvfld = rb_define_class_under(nrb,"KgcsvFLD",rb_cObject);


}


