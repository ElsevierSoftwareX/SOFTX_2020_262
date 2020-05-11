function  obj_vec=load_surv_obj_frome_result_files(Filenames)
obj_vec=[];
if ~iscell(Filenames)
    Filenames={Filenames};
end
for ifi=1:length(Filenames)
    [~,~,ext]=fileparts(Filenames{ifi});
    if isfile(Filenames{ifi})
        try
            switch ext
                case '.mat'
                    load(Filenames{ifi});
                otherwise
                    surv_obj=load_mbs_results_v2(Filenames{ifi});
            end
            if isa(surv_obj,'survey_cl')
                obj_vec = [obj_vec surv_obj];
            end
        catch
            warning('Could not load results file %s',Filenames{ifi})
        end
    end
end