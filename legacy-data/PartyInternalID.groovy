import com.sap.it.api.mapping.*;

/*Add MappingContext parameter to read or set headers and properties
def String customFunc1(String P1,String P2,MappingContext context) {
         String value1 = context.getHeader(P1);
         String value2 = context.getProperty(P2);
         return value1+value2;
}

Add Output parameter to assign the output value.
def void custFunc2(String[] is,String[] ps, Output output, MappingContext context) {
        String value1 = context.getHeader(is[0]);
        String value2 = context.getProperty(ps[0]);
        output.addValue(value1);
        output.addValue(value2);
}*/

def void partyrole(String[] role, String[] arg1, String[] arg2,  Output output, MappingContext context){
	for(int i=0; i<arg1.size(); i++){
	    if( role[i].equals("Z3") ||  role[i].equals("Z4") || role[i].equals("Z5") || role[i].equals("ZG")) {
	        output.addValue(arg2[i]);
	    }
	    else{
	        output.addValue(arg1[i]);
	    }
	}
}
