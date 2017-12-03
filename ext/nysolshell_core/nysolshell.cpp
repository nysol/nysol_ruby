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

void runCore(VALUE mlist,VALUE linklist ,vector< cmdCapselST > & cmdCapsel, vector< linkST > & p_list){

	size_t msize = RARRAY_LEN(mlist);

	for(size_t i=0 ; i<msize;i++){
		VALUE modinfo = rb_ary_entry(mlist, i);
		cmdCapselST cmpcaplocal;
		cmpcaplocal.cmdname  = RSTRING_PTR(rb_ary_entry(modinfo ,0));
		kgstr_t para_part    = RSTRING_PTR(rb_ary_entry(modinfo ,1));
		VALUE addinfo    = rb_ary_entry(modinfo ,2);
		cmpcaplocal.tag      = RSTRING_PTR(rb_ary_entry(modinfo ,3));

		cmpcaplocal.paralist = kglib::splitTokenQ(para_part, ' ',true);

		VALUE key, value;
		size_t pos = 0;
		//いい方法有れば変える（前段階arrayにした方が楽）
		VALUE addinfoAry = rb_funcall(addinfo, rb_intern("to_a"), 0);
		size_t asize = RARRAY_LEN(addinfoAry);
		for(size_t j=0 ; j<asize;j++){
			VALUE kv = rb_ary_entry(addinfoAry ,j);
			VALUE key = rb_ary_entry(kv ,0);
			VALUE value = rb_ary_entry(kv ,1);

			if(TYPE(value)==T_STRING){ 
				cmpcaplocal.paralist.push_back( kgstr_t(RSTRING_PTR(key)) + "="+ RSTRING_PTR(value) );
			}
			else if(TYPE(value)==T_ARRAY){ 
				if( kgstr_t(RSTRING_PTR(key)) == "i" ||kgstr_t(RSTRING_PTR(key)) == "m" ){
					cmpcaplocal.iobj=value;
				}
				else if( kgstr_t(RSTRING_PTR(key)) == "o" ||kgstr_t(RSTRING_PTR(key)) == "u" ){
					cmpcaplocal.oobj=value;
				}
			}
		}
		cmdCapsel.push_back(cmpcaplocal);
	}		
	/*
	struct linkST{
	kgstr_t frTP;
	int frID;
	kgstr_t toTP;
	int toID;
	};*/
	size_t lsize = RARRAY_LEN(linklist);
	for(size_t i=0 ; i<lsize;i++){
		linkST linklocal;
		VALUE linkinfo   = rb_ary_entry(linklist ,i);
		VALUE linkinfoFR = rb_ary_entry(linkinfo ,0);
		VALUE linkinfoTO = rb_ary_entry(linkinfo ,1);
		linklocal.frTP = RSTRING_PTR(rb_ary_entry(linkinfoFR ,0));
		linklocal.frID = NUM2LONG(rb_ary_entry(linkinfoFR ,1));
		linklocal.toTP = RSTRING_PTR(rb_ary_entry(linkinfoTO ,0));
		linklocal.toID = NUM2LONG(rb_ary_entry(linkinfoTO ,1));
		p_list.push_back(linklocal);
	}
	// debug
	//cerr <<  "------" << endl;
	//for(int i=0;i<cmdCapsel.size();i++){
	//	cerr << i << " " << cmdCapsel[i].cmdname << endl;
	//}
	//cerr <<  "------" << endl;
	//for(int i=0;i<p_list.size();i++){
	//	cerr << i << " " <<  p_list[i].frTP <<":" << p_list[i].frID ;
	//	cerr << " >> " <<  p_list[i].toTP << ":" << p_list[i].toID << endl; 
	//}
	//kgshell kgshell;
	// args : cmdList ,pipe_conect_List , runTYPE, return_LIST
}

VALUE runL(int argc, VALUE *argv, VALUE self)try
{
	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);

	VALUE mlist;
	VALUE linklist;
	rb_scan_args(argc, argv,"2",&mlist,&linklist);
	
	if(TYPE(mlist)!=T_ARRAY){ 
		cerr << "error  " << endl;
		return Qnil;
	} 
	vector< cmdCapselST > cmdCapsel;
	vector< linkST > p_list;
	runCore(mlist,linklist,cmdCapsel,p_list);

	rmod->run(cmdCapsel,p_list);

	return 0;

}catch(...){
	cerr << "exceptipn" << endl;
	return 1;
}


VALUE runP(VALUE self,VALUE mlist,VALUE linklist)
{
	kgshell* rmod;
	Data_Get_Struct(self,kgshell,rmod);


	if(TYPE(mlist)!=T_ARRAY){ 
		cerr << "error  " << endl;
		return Qnil;
	} 

	vector< cmdCapselST > cmdCapsel;
	vector< linkST > p_list;
	runCore(mlist,linklist,cmdCapsel,p_list);
	
	kgCSVfld* rtn = rmod->runiter(cmdCapsel,p_list);

	VALUE nrb=rb_define_module("NYSOLRUBY");
	VALUE nrcsvfld = rb_define_class_under(nrb,"KgcsvFLD",rb_cObject);
	VALUE object=Data_Wrap_Struct(nrcsvfld,0,0,rtn);

	return object;

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
}


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
	return self;	
}





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
	rb_define_method(nrbCore,"runL"       , (VALUE (*)(...))runL     ,-1);
	rb_define_method(nrbCore,"runiter"    , (VALUE (*)(...))runP     ,2);
	rb_define_method(nrbCore,"readline"   , (VALUE (*)(...))readline ,1);
	rb_define_method(nrbCore,"getparalist", (VALUE (*)(...))getparams,1);

	VALUE nrcsvfld = rb_define_class_under(nrb,"KgcsvFLD",rb_cObject);


}




