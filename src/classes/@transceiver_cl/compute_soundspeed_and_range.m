function [c,range_t]=compute_soundspeed_and_range(trans_obj,env_data_obj,ori)
arguments
    trans_obj transceiver_cl
    env_data_obj env_data_cl
    ori string=''
end

try   
    if isempty(ori)||strcmp(ori,'')
        ori=env_data_obj.SVP.ori;
    end
    if isempty(env_data_obj.SVP.depth)&&strcmpi(ori,'profile')
        ori='constant';
    end
    
    switch ori
        case 'constant'
            c = env_data_obj.SoundSpeed;
            range_t= get_linear_range(trans_obj,c);
        case {'theoritical' 'profile'}
            t_angle=trans_obj.get_transducer_pointing_angle();
            time_r = (trans_obj.Data.get_samples()-1) * trans_obj.get_params_value('SampleInterval',1);
            d_max=1600*time_r(end)/2+nanmax(trans_obj.get_transducer_depth());
            switch ori
                case 'theoritical'
                    dr=(1500*mode(diff(time_r)/2));
                    d_ref=(0:dr:d_max)';
                    c_ref=seawater_svel_un95(env_data_obj.Salinity,env_data_obj.Temperature,d_ref);
                case 'profile'
                    d_ref=env_data_obj.SVP.depth(:);
                    c_ref=env_data_obj.SVP.soundspeed();
            end
            
            
            dr=(1400*mode(diff(time_r)/2));
            d_th=(0:dr:d_max)';
            
            c_init=resample_data_v2(c_ref,d_ref,d_th);
            
            if any(isnan(c_init))
                print_errors_and_warnings([],'warning',sprintf('Soundspeed profile provided does not cover the full depth range of the data here... \nCompleting with standard profile based on provided average temperature and Salinity.'))
                default_ss=seawater_svel_un95(env_data_obj.Salinity,env_data_obj.Temperature,d_th);
                c_init(isnan(c_init))=default_ss(isnan(c_init));
                
                if 0
                    h_fig=new_echo_figure([],'tag','soundspeed');
                    ax1=axes(h_fig,'nextplot','add','outerposition',[0 0 1 1],'box','on','nextplot','add');
                    plot(ax1,c_init,d_th,'r');
                    plot(ax1,c_ref,d_ref,'g');
                    plot(ax1,default_ss,d_th,'b');
                    axis(ax1,'ij');
                    ylabel(ax1,'Depth (m)');
                    ylim(ax1,[0 max(d_th)]);
                    xlabel(ax1,'Soundspeed (m/s)');
                end
            end
            
            [r_ray,t_ray,z_ray,~]=compute_acoustic_ray_path(d_th,c_init,0,0,nanmean(trans_obj.get_transducer_depth),t_angle,3*time_r(end)/4);
            d_trans_new=sqrt(r_ray.^2+z_ray.^2);
            
            range_t_new=(d_trans_new-trans_obj.get_transducer_depth(1))/sin(t_angle);
            [~,id_start]=find(range_t_new>=0,1,'first');
            range_t_new=range_t_new(id_start:end);
            t_ray=t_ray(id_start:end);
            t_ray=t_ray-t_ray(1);
            range_t=resample_data_v2(range_t_new,t_ray*2,time_r);
            c=resample_data_v2(c_init,d_th,range_t*sin(t_angle)+trans_obj.get_transducer_depth(1));
            c=c(:);
        otherwise
            c = env_data_obj.SoundSpeed;
            range_t= get_linear_range(trans_obj,c);
    end
    
catch err
    print_errors_and_warnings([],'warning',err);
    c = env_data_obj.SoundSpeed;
    range_t= get_linear_range(trans_obj,c);
end
end


function range_t=get_linear_range(trans_obj,c)

t = trans_obj.Params.SampleInterval(1);

dR=double(c .* t / 2);

samples=trans_obj.get_transceiver_samples();

range_t=double(samples-1)*dR;

end

