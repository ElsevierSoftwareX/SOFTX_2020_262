function trans_out = concatenate_Transceivers(trans_1,trans_2,envdata_1,envdata_2)

if isempty(trans_1)
    trans_out=trans_2;
    return;
elseif isempty(trans_2)
    trans_out=trans_1;
    return;
end

if length(trans_1)==length(trans_2)
    trans_out(length(trans_1))=transceiver_cl();
    for i=1:length(trans_1)
        if trans_1(i).Time(1)>=trans_2(i).Time(end)
            trans_first=trans_2(i);
            trans_second=trans_1(i);
        else
            trans_first=trans_1(i);
            trans_second=trans_2(i);
        end
        
        [~, r_1] = trans_1(i).compute_soundspeed_and_range(envdata_1);
        [~, r_2] = trans_2(i).compute_soundspeed_and_range(envdata_2);

        [alpha_1,ori_alpha_1] = trans_1(i).compute_absorption(envdata_1);
        [alpha_2,ori_alpha_2] = trans_2(i).compute_absorption(envdata_2);
        
        cal_1=trans_1(i).get_cal();
        cal_2=trans_2(i).get_cal();
        cal_diff=false;
        
        if cal_1.G0~=cal_2.G0||cal_1.SACORRECT~=cal_2.SACORRECT||cal_1.EQA~=cal_2.EQA
            trans_2(i).set_cal(cal_1);
            cal_diff=true;
        end
        
        [~,found_sv_1]=trans_1(i).Data.find_field_idx('sv');
        [~,found_sv_2]=trans_2(i).Data.find_field_idx('sv');
          
        if (found_sv_1&&found_sv_2)&&(~isempty(setxor(round(alpha_1*1e6),round(alpha_2*1e6)))||~isempty(setxor(r_1,r_2))||~strcmpi(ori_alpha_1,ori_alpha_2)||cal_diff)
            trans_2(i).set_cal(cal_1);
            
            switch ori_alpha_1
                case 'constant'
                    trans_2(i).set_absorption(alpha_1);
                otherwise
                    trans_2(i).set_absorption(envdata_1);
            end
            
            trans_2(i).computeSpSv_v3(envdata_1);
        end
        
        [~, r_2] = trans_2(i).compute_soundspeed_and_range(envdata_1);
        [alpha_2,~] = trans_2(i).compute_absorption(envdata_1);
        
        if numel(r_1)>numel(r_2)
            r=r_1;
            alpha=alpha_1;
        else
            r=r_2;
            alpha=alpha_2;
        end
        
        
        trans_out(i)=transceiver_cl('Data',concatenate_Data(trans_first.Data,trans_second.Data),...
            'Range',r,...
            'Alpha',alpha,...
            'TransducerDepth',[trans_first.TransducerDepth trans_second.TransducerDepth],...
            'TransducerImpedance',[trans_first.TransducerImpedance trans_second.TransducerImpedance],...
            'Alpha_ori',ori_alpha_1,...
            'Time',[trans_first.Time trans_second.Time],...
            'Algo',trans_first.Algo,...
            'GPSDataPing',concatenate_GPSData(trans_first.GPSDataPing,trans_second.GPSDataPing),...
            'Mode',trans_first.Mode,...
            'AttitudeNavPing',concatenate_AttitudeNavPing(trans_first.AttitudeNavPing,trans_second.AttitudeNavPing),...
            'Params',concatenate_Params(trans_first.Params,trans_second.Params,numel(trans_first.Time),numel(trans_second.Time)),...
            'Config',trans_first.Config,...
            'Filters',trans_first.Filters);
        
        trans_out(i).Spikes(1:size(trans_first.Spikes,1),1:size(trans_first.Spikes,2))=trans_first.Spikes;
        trans_out(i).Spikes(1:size(trans_second.Spikes,1),(1:size(trans_second.Spikes,2))+size(trans_first.Spikes,2))=trans_second.Spikes;
        
        % concatenate bottom
        new_bot = concatenate_Bottom(trans_first.Bottom,trans_second.Bottom);
        trans_out(i).Bottom = new_bot;
        
        % cumulate regions
        regions_1 = trans_first.Regions;
        regions_2 = trans_second.Regions;
        trans_out(i).add_region(regions_1);
        trans_out(i).add_region(regions_2,'Ping_offset',-(numel(trans_first.Time)));
        
        
    end
else
    error('Cannot concatenate two files with diff frequencies')
end
end