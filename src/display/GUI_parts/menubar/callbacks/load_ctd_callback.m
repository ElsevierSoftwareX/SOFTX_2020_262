function load_ctd_callback(~,~,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

if isempty(layer)
    return;
end

[path_file,~,~]=fileparts(layer.Filename{1});
[ctd_filename,ctd_path]= uigetfile( {fullfile(path_file,'*.cnv*')}, 'Pick a Seabird CTD file','MultiSelect','off');
if ~(ctd_filename~=0)
    return;
end

try
    [temp,sal,depth,~,~,~]=read_seabird(fullfile(ctd_path,ctd_filename));
catch
    disp('Could not read seabird file');
    return;
end

if isempty(temp)||isempty(sal)||isempty(depth)
    disp('Could not read seabird file');
    return;
end

trans_obj=layer.get_trans(curr_disp);

depth_t=trans_obj.get_transceiver_depth([],1);
idx_keep=(depth>0);

depth(~idx_keep)=[];
sal(~idx_keep)=[];
temp(~idx_keep)=[];


[d_max,id_max]=nanmax(depth);

[~,idx]=sort(depth);

id_d=intersect(idx,1:id_max,'stable');
id_u=setdiff(idx,id_d,'stable');

h_fig=new_echo_figure(main_figure);
ax1=axes(h_fig,'nextplot','add','outerposition',[0 0 0.5 1],'box','on');
plot(ax1,temp(id_d),depth(id_d),'r');
plot(ax1,temp(id_u),depth(id_u),'b');
ax2=axes(h_fig,'nextplot','add','outerposition',[0.5 0 0.5 1],'box','on');
plot(ax2,sal(id_d),depth(id_d),'r');
plot(ax2,sal(id_u),depth(id_u),'b');
axis([ax1 ax2],'ij');
ylabel(ax1,'Depth (m)');
ylim([ax1 ax2],[0 d_max]);
xlabel(ax1,'Temperature (deg.)');
xlabel(ax2,'Salinity (PSU)');
legend(ax1,'Down cast','Up Cast')

fname=fullfile(ctd_path,ctd_filename);
[~,ff,~]=fileparts(fname);

layer.EnvData=layer.EnvData.set_ctd(depth(id_d),temp(id_d),sal(id_d),'');
layer.EnvData.save_ctd(fullfile(ctd_path,[ff '.espctd']));
update_environnement_tab(main_figure,1);
layer.layer_computeSpSv();

end