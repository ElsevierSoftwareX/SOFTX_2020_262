function [alpha,ori]=compute_absorption(trans_obj,env_data_obj,ori)

arguments
    trans_obj transceiver_cl
    env_data_obj env_data_cl=env_data_cl()
    ori string=''
end

try
    FreqStart=(trans_obj.get_params_value('FrequencyStart',1));
    FreqEnd=(trans_obj.get_params_value('FrequencyEnd',1));
    %f_nom=(trans_obj.Config.Frequency);
    f_c=(FreqStart+FreqEnd)/2;
    
    if FreqEnd>=120000||FreqStart>=120000
        att_model='fandg';
    else
        att_model='doonan';
    end
    
    if isempty(ori)||strcmp(ori,'')
        ori=env_data_obj.CTD.ori;
    end
    d_trans=trans_obj.get_transceiver_depth([],1);
    default_alpha=seawater_absorption(f_c/1e3, env_data_obj.Salinity, env_data_obj.Temperature, d_trans,att_model)/1e3;
    
    trans_obj.Alpha(isnan(trans_obj.Alpha))=default_alpha(isnan(trans_obj.Alpha));
    
    if isempty(env_data_obj.CTD.depth)&&strcmpi(ori,'profile')
        ori='constant';
    end
    
    switch ori
        case 'constant'
            alpha = nanmean(trans_obj.Alpha);
            alpha =alpha*ones(size(trans_obj.Range));
        case 'theoritical'
            
            alpha=seawater_absorption(f_c/1e3, env_data_obj.Salinity, env_data_obj.Temperature, d_trans,att_model)/1e3;
            alpha=alpha(:);
            
        case 'profile'
            alpha_ori = trans_obj.Alpha;
            
            d_trans=trans_obj.get_transceiver_depth([],1);
            alpha=resample_data_v2(alpha_ori,env_data_obj.CTD.depth,d_trans);
            
            if any(isnan(alpha))
                print_errors_and_warnings([],'warning',sprintf('CTD profile provided does not cover the full depth range of the data here...\nCompleting with standard profile based on provided average temperature and Salinity.'))
                alpha(isnan(alpha))=default_alpha(isnan(alpha));
            end
            alpha=alpha(:);
            
            if 0
                h_fig=new_echo_figure([],'tag',sprintf('absorption%.0f',f_c));
                ax1=axes(h_fig,'nextplot','add','outerposition',[0 0 1 1],'box','on');
                plot(ax1,alpha,d_trans,'r');
                axis(ax1,'ij');
                ylabel(ax1,'Depth (m)');
                ylim(ax1,[0 max(d_trans)]);
                xlabel(ax1,'Absorption (dB/km)');
                title(ax1,sprintf('absorption profile at %.0kHz',f_c));
            end
            ori='profile';
        otherwise
            alpha = nanmean(trans_obj.Alpha);
            alpha =alpha*ones(size(trans_obj.Range));
            ori='constant';
    end
    
    
    
catch err
    print_errors_and_warnings([],'warning',err);
    alpha = nanmean(trans_obj.Alpha);
    alpha = alpha*ones(size(trans_obj.Range));
    ori='constant';
end

end