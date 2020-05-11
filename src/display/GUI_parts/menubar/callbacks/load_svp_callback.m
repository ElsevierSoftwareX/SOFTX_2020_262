function load_svp_callback(~,~,main_figure) 
layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');

if isempty(layer)
    return;
end
    
[path_file,~,~]=fileparts(layer.Filename{1});
[svp_filename,svp_path]= uigetfile( {fullfile(path_file,'*.asvp*')}, 'Pick a Svp file','MultiSelect','off');   
    if svp_filename~=0
        u=importdata(fullfile(svp_path,svp_filename));
        z_c=u.data(:,1);
        c=u.data(:,2);
    else

        choice=question_dialog_fig(main_figure,'','Do you want to continue with no SVP and constant velocity profile?');
        % Handle response
        switch choice
            case 'Yes'
                z_c=1:2*1e4;
                c=layer.EnvData.SoundSpeed*ones(size(z_c));
            otherwise
                return;
        end
        
        if isempty(choice)
            return;
        end
    end
    
z_interp=z_c(1):0.5:z_c(end);  

c_interp=interpn(z_c,c,z_interp,'linear');

trans_obj=layer.get_trans(curr_disp);

depth=trans_obj.get_transceiver_depth([],1);

idx_disp=z_interp>depth(end);

figure();
plot(c_interp(idx_disp),z_interp(idx_disp),'-o');
hold on;
plot(c,z_c,'-+');
axis ij;
ylim([z_interp(1) nanmax(z_interp(idx_disp))]);
xlabel('SoundSpeed(m/s)');
ylabel('Depth (m)');
grid on;
legend('Interpolated','Measured');

fname=fullfile(svp_path,svp_filename);
[~,ff,~]=fileparts(fname);
layer.set_EnvData(layer.EnvData.set_svp(z_c,c,''));
layer.EnvData.save_svp(fullfile(ctd_path,[ff '.espsvp']));
update_environnement_tab(main_figure,1);
layer.layer_computeSpSv();

end