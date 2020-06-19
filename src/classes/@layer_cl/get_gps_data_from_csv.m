function get_gps_data_from_csv(layer_obj,filenames,dt)

gps_data_tot=gps_data_cl.empty();
if isempty(filenames)
    filenames=cellfun(@generate_gps_default_fname,layer_obj.Filename,'un',0);
end

up=0;
for ui=1:numel(filenames)
    if isfile(filenames{ui})
        try
            fprintf('Using %s file as GPS input.\n',filenames{ui});
            gps_data_tmp=gps_data_cl.load_gps_from_file(filenames{ui});
            gps_data_tot=concatenate_GPSData(gps_data_tot,gps_data_tmp);
        catch err
            print_errors_and_warnings(1,'warning',err);
        end
        up=1;
    end
end
if up>0
    gps_data_tot.Time=gps_data_tot.Time+dt/24;
    layer_obj.replace_gps_data_layer(gps_data_tot);
    layer_obj.add_ping_data_to_db([],1);
end
end

function gps_file=generate_gps_default_fname(fname)
[path_f,fname,~]=fileparts(fname);
gps_file=fullfile(path_f,[fname '_gps.csv']);
end