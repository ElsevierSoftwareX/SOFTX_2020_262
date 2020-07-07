function layer_computeSpSv(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'calibration',[]);
addParameter(p,'new_soundspeed',nan,@isnumeric);
addParameter(p,'absorption',[],@isnumeric);
addParameter(p,'absorption_f',[],@isnumeric);
addParameter(p,'force',false,@islogical);
addParameter(p,'load_bar_comp',[]);

parse(p,layer_obj,varargin{:});
up_ss=false;
up_abs=false(1,numel(layer_obj.Frequencies));

if ~isnan(p.Results.new_soundspeed)
    up_ss=abs(p.Results.new_soundspeed-layer_obj.EnvData.SoundSpeed)>1e-2;
    if up_ss
        layer_obj.EnvData.SoundSpeed=p.Results.new_soundspeed;
    end
end

for ichan=1:numel(layer_obj.Frequencies)
    [~,range_comp]=layer_obj.Transceivers(ichan).compute_soundspeed_and_range(layer_obj.EnvData);
    range_t=layer_obj.Transceivers(ichan).get_transceiver_range();
    if any(size(range_t)~=size(range_comp))||any(range_t~=range_comp)
        layer_obj.Transceivers(ichan).set_transceiver_range(range_t);
        up_ss=true;
    end
end

cal_tot=extract_cal_to_apply(layer_obj,p.Results.calibration);

abs_cal=cal_tot.alpha/1e3;
abs_cal_f=cal_tot.FREQ;

if isempty(p.Results.absorption)
    abs_to_apply=abs_cal;
    abs_to_apply_f=abs_cal_f;
else
    abs_to_apply=p.Results.absorption;
    abs_to_apply_f=p.Results.absorption_f;
end

if ~isempty(abs_to_apply)
    for ichan=1:numel(layer_obj.Frequencies)
         
        idx_abs=find(layer_obj.Frequencies(ichan)==abs_to_apply_f,1);
        [alpha_curr,ori]=layer_obj.Transceivers(ichan).get_absorption();
        [alpha_comp,ori_comp]=layer_obj.Transceivers(ichan).compute_absorption(layer_obj.EnvData);
        if strcmpi(ori,ori_comp)
            switch ori_comp
                case 'constant'
                    if ~isempty(idx_abs)
                        if any(abs(alpha_curr-abs_to_apply(idx_abs))>1e-5)
                            up_abs(ichan)=true;
                            layer_obj.Transceivers(ichan).set_absorption(abs_to_apply(idx_abs));
                        end
                    end
                otherwise
                    if any(alpha_curr~=alpha_comp)
                        layer_obj.Transceivers(ichan).set_absorption(layer_obj.EnvData);
                        up_abs(ichan)=true;
                    end
            end
        else
            up_abs(ichan)=true;
            switch ori_comp
                case 'constant'
                    if ~isempty(idx_abs)
                        layer_obj.Transceivers(ichan).set_absorption(abs_to_apply(idx_abs));
                    else
                        layer_obj.Transceivers(ichan).set_absorption(nan);
                    end
                otherwise
                    layer_obj.Transceivers(ichan).set_absorption(layer_obj.EnvData);
                    if any(alpha_curr~=alpha_comp)
                        up_abs(ichan)=true;
                    end
            end
        end
        
        
    end
end

%[cal_fm,ori_cal_fm]=layer_obj.get_fm_cal([]);

for ichan=1:numel(layer_obj.Frequencies)
    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText(sprintf('Computing Sv and Sp for %s',layer_obj.ChannelID{ichan}));
    end
    if ~isempty(cal_tot)
        idx_cal=find(strcmp(cal_tot.CID,layer_obj.ChannelID{ichan})&~cellfun(@isempty,cal_tot.CID),1);
        if isempty(idx_cal)
            idx_cal=find(cal_tot.FREQ==layer_obj.Frequencies(ichan));
        end
        if ~isempty(idx_cal)
            cal_t=struct('EQA',cal_tot.EQA(idx_cal),'G0',cal_tot.G0(idx_cal),'SACORRECT',cal_tot.SACORRECT(idx_cal));
        end
    else
        cal_t=layer_obj.Transceivers(ichan).get_cal();
    end
    
    [~,found_sp]=layer_obj.Transceivers(ichan).Data.find_field_idx('sp');
    [~,found_sv]=layer_obj.Transceivers(ichan).Data.find_field_idx('sv');
    
    if up_ss||up_abs(ichan)||(~found_sp)||(~found_sv)||p.Results.force
        layer_obj.Transceivers(ichan).set_cal(cal_t);
        layer_obj.Transceivers(ichan).computeSpSv_v3(layer_obj.EnvData,'load_bar_comp',p.Results.load_bar_comp);
    else
        layer_obj.Transceivers(ichan).apply_cw_cal(cal_t);
    end
end


end