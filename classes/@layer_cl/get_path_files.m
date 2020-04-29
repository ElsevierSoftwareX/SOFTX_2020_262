function [path_lay,files_lay]=get_path_files(layer_obj)

path_lay={};
files_lay={};

for il=1:length(layer_obj)
    [path_lay_tmp,files_lay_tmp,ext_lay]=cellfun(@fileparts,layer_obj(il).Filename,'UniformOutput',0);
    
    files_lay_tmp=cellfun(@(x,y) deblank([x y]),files_lay_tmp,ext_lay,'un',0);

    path_lay=[path_lay path_lay_tmp];
    files_lay=[files_lay files_lay_tmp];
end