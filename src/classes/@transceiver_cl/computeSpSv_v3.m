function computeSpSv_v3(trans_obj,env_data_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'env_data_obj',@(obj) isa(obj,'env_data_cl'));

addParameter(p,'load_bar_comp',[]);
addParameter(p,'FieldNames',{},@iscell);
addParameter(p,'Type','uncomp',@ischar);
addParameter(p,'block_len',get_block_len(5,'gpu'),@(x) x>0);

if ~isdeployed()
    tic;
    %profile on;
end

parse(p,trans_obj,env_data_obj,varargin{:});


[c,range_t_ori]=trans_obj.compute_soundspeed_and_range(env_data_obj);
trans_obj.set_transceiver_range(range_t_ori);

trans_obj.set_absorption(env_data_obj);

alpha=trans_obj.get_absorption();

cal_cw=trans_obj.get_cal();

fprintf('Computing Sp and Sv values:\n');
trans_obj.disp_calibration_env_params(env_data_obj);

eq_beam_angle = trans_obj.Config.EquivalentBeamAngle;

f_nom = trans_obj.Config.Frequency;

f_c=trans_obj.get_center_frequency();

eq_beam_angle_c=eq_beam_angle+20*log10(f_nom./f_c);

G=cal_cw.G0+20*log10(f_c./f_nom);

% G=cal_cw.G0
% eq_beam_angle_c=eq_beam_angle

ptx = trans_obj.get_params_value('TransmitPower',[]);
[t_eff,~]=trans_obj.get_pulse_Teff();
[t_eff_comp,~]=trans_obj.get_pulse_comp_Teff();
[t_nom,~]=trans_obj.get_pulse_length();
sacorr = cal_cw.SACORRECT;

pings=trans_obj.get_transceiver_pings();

nb_samples=numel(range_t_ori);
nb_pings=numel(pings);

%[gpu_comp,g]=get_gpu_comp_stat();
gpu_comp=0;

% if gpu_comp%use of gpuArray results in about 20% speed increase here
%     gpuDevice(1);
% end

bsize=ceil(p.Results.block_len/nb_samples);
u=0;

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.set('Minimum',0,'Maximum',ceil(nb_pings/bsize),'Value',0);
end

while u<ceil(nb_pings/bsize)
    idx_pings=(u*bsize+1):nanmin(((u+1)*bsize),nb_pings);
    u=u+1;
    
    pow=trans_obj.Data.get_subdatamat(1:nb_samples,idx_pings,'field','power');
    powunmatched=trans_obj.Data.get_subdatamat(1:nb_samples,idx_pings,'field','powerunmatched');
    
    if gpu_comp%use of gpuArray results in about 20% speed increase here
        if g.AvailableMemory/(8*4*5)<=bsize*nb_samples
            gpuDevice(1);
        end
        pow=gpuArray(pow);
        range_t=gpuArray(range_t_ori);
        powunmatched=gpuArray(powunmatched);
        ptx_idx_pings=gpuArray(ptx(idx_pings));
    else
        ptx_idx_pings=ptx(idx_pings);
        range_t=range_t_ori;
    end
    

    
    switch trans_obj.Mode
        
        
        case 'FM'

            
            [Sp,Sv]=convert_power_v2(pow,range_t,c,alpha,t_eff_comp(idx_pings),t_nom(idx_pings),ptx_idx_pings,c./f_c(idx_pings),G(idx_pings),eq_beam_angle_c(idx_pings),sacorr,trans_obj.Config.TransceiverName);
            
            if any(strcmpi(p.Results.FieldNames,'sp'))||isempty(p.Results.FieldNames)&&~isempty(powunmatched)
                [Sp_un,Sv_un]=convert_power_v2(powunmatched,range_t,c,alpha,t_eff(idx_pings),t_nom(idx_pings),ptx_idx_pings,c./f_c(idx_pings),G(idx_pings),eq_beam_angle_c(idx_pings),sacorr,trans_obj.Config.TransceiverName);
                if  isa(Sp_un,'gpuArray')
                    Sp_un=gather(Sp_un);
                    Sv_un=gather(Sv_un);
                end
                trans_obj.Data.replace_sub_data_v2('spunmatched',Sp_un,[],idx_pings);
                trans_obj.Data.replace_sub_data_v2('svunmatched',Sv_un,[],idx_pings);
            end
            
        case 'CW'
            
            switch trans_obj.Config.TransceiverType
                case list_WBTs()
                    
                otherwise
                    t_eff=t_nom;
            end
            
            [Sp,Sv]=convert_power_v2(pow,range_t,c,alpha,t_eff(idx_pings),t_nom(idx_pings),ptx_idx_pings,c./f_c(idx_pings),G(idx_pings),eq_beam_angle_c(idx_pings),sacorr,trans_obj.Config.TransceiverName);
            
    end
    
    if any(strcmpi(p.Results.FieldNames,'sv'))||isempty(p.Results.FieldNames)
        if isa(Sv,'gpuArray')
            Sv=gather(Sv);
        end
        trans_obj.Data.replace_sub_data_v2('sv',Sv,[],idx_pings);
        clear Sv;
    end
    if any(strcmpi(p.Results.FieldNames,'sp'))||isempty(p.Results.FieldNames)
        if  isa(Sp,'gpuArray')
            Sp=gather(Sp);
        end
        trans_obj.Data.replace_sub_data_v2('sp',Sp,[],idx_pings);
        clear Sp;
    end
    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.set('Value',u);
    end
end

if ~isdeployed()
    t=toc;
    fprintf('Sp and Sv values computed in %.2f seconds\n',t);
    %    profile off
    %    profile viewer;
end

end