function str=vec2delem_str(vec,delim,prec)

str=strjoin(arrayfun(@(x) num2str(x,prec),vec,'UniformOutput',0),delim);