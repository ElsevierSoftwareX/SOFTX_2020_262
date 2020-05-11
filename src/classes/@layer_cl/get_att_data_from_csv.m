function get_att_data_from_csv(layer_obj,filenames,dt)

att_data_tot=attitude_nav_cl.empty();
if isempty(filenames)
    filenames=cellfun(@generate_att_defalut_fname,layer_obj.Filename,'un',0);
end

up=0;
for ui=1:numel(filenames)
    if isfile(filenames{ui})
        try
            fprintf('Using %s file as attitude input.\n',filenames{ui});
            att_data_tmp=att_data_cl.load_att_from_file(filenames{ui});
            att_data_tot=concatenate_AttitudeNavPing(att_data_tot,att_data_tmp);
        catch err
            print_errors_and_warnings(1,'warning',err);
        end
        up=1;
    end
end
if up>0
    att_data_tot.Time=att_data_tot.Time+dt/24;
    layer_obj.add_attitude(att_data_tot);
end
end

function att_file=generate_att_defalut_fname(fname)
[path_f,fname,~]=fileparts(fname);
att_file=fullfile(path_f,[fname '_att.csv']);
end