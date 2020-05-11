function spheres_struct=list_spheres(varargin)
   
app_path_main=whereisEcho();
config_path=fullfile(app_path_main,'config');
spheres_struct=read_sphere_xml(fullfile(config_path,'spheres.xml'));

if nargin>=1
   idx= strcmpi({spheres_struct(:).name},varargin{1});
   if any(idx)
     spheres_struct=spheres_struct(idx);
   else
       spheres_struct={};
   end
end

end