classdef path_elt_cl < handle
    
    properties 
        Path_to_folder char
        Path_description char
        Path_tooltipstring char
        Path_fieldname char
    end
    
    methods
        function path_elt_obj=path_elt_cl(path_to_folder,varargin)
            
            p = inputParser;
            addRequired(p,'path_to_folder',@ischar);
            addParameter(p,'Path_description',path_to_folder,@ischar);
            addParameter(p,'Path_tooltipstring',path_to_folder,@ischar);
            addParameter(p,'Path_fieldname',genvarname(path_to_folder),@ischar);
            parse(p,path_to_folder,varargin{:});
            
            if ~isfolder(path_to_folder)
                try
                    mkdir(path_to_folder);
                catch
                    if ~contains(p.Results.Path_fieldname,'cvs')
                        disp_perso([],sprintf('Could not create folder %s',path_to_folder));
                        path_to_folder=whereisEcho();
                    end
                end
            end
            path_elt_obj.Path_description = p.Results.Path_description;
            path_elt_obj.Path_tooltipstring = p.Results.Path_tooltipstring; 
            path_elt_obj.Path_fieldname = p.Results.Path_fieldname; 
            path_elt_obj.Path_to_folder = path_to_folder;

        end
        
        function set.Path_to_folder(obj,pp)
            if ~isfolder(pp)
                try
                    mkdir(pp);
                catch
                    if ~isdeployed()
                        disp_perso([],sprintf('Could not create folder %s',pp));
                    end
                end
            end
            obj.Path_to_folder = pp;      
        end
        
    end
end
