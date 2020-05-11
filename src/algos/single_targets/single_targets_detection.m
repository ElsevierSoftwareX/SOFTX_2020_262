function output_struct=single_targets_detection(trans_obj,varargin)
%SINGLE_TARGET_DETECTION
%profile on;
%Parse Arguments
p = inputParser;

check_trans_cl=@(obj)isa(obj,'transceiver_cl');
defaultTsThr=-50;
checkTsThr=@(thr)(thr>=-120&&thr<=0);
defaultPLDL=6;
checkPLDL=@(PLDL)(PLDL>=1&&PLDL<=30);
defaultMinNormPL=0.7;
defaultMaxNormPL=1.5;
checkNormPL=@(NormPL)(NormPL>=0.0&&NormPL<=10);
defaultMaxBeamComp=4;
checkBeamComp=@(BeamComp)(BeamComp>=0&&BeamComp<=18);
defaultMaxStdMinAxisAngle=0.6;
checkMaxStdMinAxisAngle=@(MaxStdMinAxisAngle)(MaxStdMinAxisAngle>=0&&MaxStdMinAxisAngle<=45);
defaultMaxStdMajAxisAngle=0.6;
checkMaxStdMajAxisAngle=@(MaxStdMajAxisAngle)(MaxStdMajAxisAngle>=0&&MaxStdMajAxisAngle<=45);

check_data_type=@(datatype) ischar(datatype)&&(nansum(strcmp(datatype,{'CW','FM'}))==1);


addRequired(p,'trans_obj',check_trans_cl);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'TS_threshold',defaultTsThr,checkTsThr);
addParameter(p,'TS_threshold_max',0,checkTsThr);
addParameter(p,'PLDL',defaultPLDL,checkPLDL);
addParameter(p,'MinNormPL',defaultMinNormPL,checkNormPL);
addParameter(p,'MaxNormPL',defaultMaxNormPL,checkNormPL);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'MaxBeamComp',defaultMaxBeamComp,checkBeamComp);
addParameter(p,'MaxStdMinAxisAngle',defaultMaxStdMinAxisAngle,checkMaxStdMinAxisAngle);
addParameter(p,'MaxStdMajAxisAngle',defaultMaxStdMajAxisAngle,checkMaxStdMajAxisAngle);
addParameter(p,'DataType',trans_obj.Mode,check_data_type);
addParameter(p,'block_len',get_block_len(50,'cpu'),@(x) x>0);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

output_struct.done =  false;

if isempty(p.Results.reg_obj)
    idx_r_tot=1:length(trans_obj.get_transceiver_range());
    idx_pings_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r_tot,'Idx_pings',idx_pings_tot);
else
    reg_obj=p.Results.reg_obj;
end
idx_pings_tot=reg_obj.Idx_pings;
idx_r_tot=reg_obj.Idx_r;

range_tot = trans_obj.get_transceiver_range(idx_r_tot);

if ~isempty(idx_r_tot)
    idx_r_tot(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r_tot)
    disp_perso([],'Nothing to detect single targets from...');
    output_struct.single_targets=init_st_struct();
    output_struct.done =  false;
    return;
end


if isempty(p.Results.reg_obj)
    reg_obj=region_cl('Idx_r',idx_r_tot,'Idx_pings',idx_pings_tot);
else
    reg_obj=p.Results.reg_obj;
end
up_bar=~isempty(p.Results.load_bar_comp);
Number_tot=trans_obj.get_transceiver_pings();
Range_tot=trans_obj.get_transceiver_range();
nb_samples_tot=length(Range_tot);
nb_pings_tot=length(Number_tot);

Idx_samples_lin_tot=reshape(1:nb_samples_tot*nb_pings_tot,nb_samples_tot,nb_pings_tot);

max_TS=p.Results.TS_threshold_max;
min_TS=p.Results.TS_threshold;

if max_TS<=min_TS
    warndlg_perso([],'Invalid params','Invalid parameters for Single Target detection (TS thresholds)');
   return; 
end

trans_obj.rm_tracks();

block_size=nanmin(ceil(p.Results.block_len/numel(idx_r_tot)),numel(idx_pings_tot));

num_ite=ceil(numel(idx_pings_tot)/block_size);

if up_bar
    p.Results.load_bar_comp.progress_bar.setText('Single Target detection');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

heading=trans_obj.AttitudeNavPing.Heading(:)';
pitch=trans_obj.AttitudeNavPing.Pitch(:)';
roll=trans_obj.AttitudeNavPing.Roll(:)';
heave=trans_obj.AttitudeNavPing.Heave(:)';
yaw=trans_obj.AttitudeNavPing.Yaw(:)';
dist=trans_obj.GPSDataPing.Dist(:)';

pitch(isnan(pitch))=0;

roll(isnan(roll))=0;

heave(isnan(heave))=0;

dist(isnan(dist))= 0;


if isempty(dist)
    dist=zeros(1,nb_pings_tot);
end

if isempty(heading)||all(isnan(heading))||all(heading==-999)
    heading=zeros(1,nb_pings_tot);
end

if isempty(roll)
    roll=zeros(1,nb_pings_tot);
    pitch=zeros(1,nb_pings_tot);
    heave=zeros(1,nb_pings_tot);
end

single_targets_tot=[];

if p.Results.denoised
    field='spdenoised';
else
    field = 'sp';
end

if ~ismember(field,trans_obj.Data.Fieldname)
    field='sp';
end


    BW_athwart=trans_obj.Config.BeamWidthAthwartship;
    BW_along=trans_obj.Config.BeamWidthAlongship;
for ui=1:num_ite
    idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
    
    idx_r=idx_r_tot;
    
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_pings',idx_pings);
    
    [TS,idx_r,idx_pings,bad_data_mask,bad_trans_vec,inter_mask,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,'field',field,...
        'intersect_only',1,...
        'regs',reg_obj);
    
    Power= trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','power');
    
    mask=bad_data_mask|below_bot_mask|~inter_mask;
    
    mask(:,bad_trans_vec)=1;
    
   
    idx_r=idx_r(:);
    idx_pings=idx_pings(:)';

    if isempty(TS)
        warndlg_perso([],'No TS','Cannot find single targets with no TS datagram...');
        output_struct.single_targets=[];
        return;
    end
    
    [nb_samples,nb_pings]=size(TS);
    [~,N]=trans_obj.get_pulse_length(idx_pings);
    N=nanmax(N);
    Idx_samples_lin=Idx_samples_lin_tot(idx_r,idx_pings);
    r=trans_obj.get_transceiver_range(idx_r);
    r_p=trans_obj.get_transceiver_range(N);
    Range=repmat(r,1,nb_pings);
    

    TS(mask>=1)=-999;
    Power(mask>=1)=-999;
    
    if ~any(TS(:)>-999)
        continue;
    end
    Range(mask)=nan;
    
    [~,idx_r_max]=nanmin(abs(r-nanmax(Range(TS>-999))));
    
    [~,idx_r_min]=nanmin(abs(r-nanmin(Range(TS>-999))));
    idx_r_min_p=find(r>r_p,1);
    if ~isempty(idx_r_min_p)
        idx_r_min=nanmax(idx_r_min_p,idx_r_min);
    end
    
    %idx_r_min=1;
    idx_rem=[];
    
    %     idx_r_max=idx_r_max+N;
    %     idx_r_min=idx_r_min-N;
    
  
    if idx_r_max<nb_samples
        idx_rem=union(idx_rem,idx_r_max:nb_samples);
    end
    
    if idx_r_min>1
        idx_rem=union(idx_rem,1:idx_r_min);
    end

    %%%%%%%Remove all unnecessary data%%%%%%%%

    idx_r(idx_rem)=[];
    TS(idx_rem,:)=[];
    Power(idx_rem,:)=[];
    Idx_samples_lin(idx_rem,:)=[];
    [nb_samples,nb_pings]=size(TS);
    along=trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','AlongAngle');
    athwart=trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','AcrossAngle');
    
    if isempty(along)||isempty(along)
        disp('Computing using single beam data');
        along=zeros(size(TS));
        athwart=zeros(size(TS));
    end
    
    Range=repmat(trans_obj.get_transceiver_range(idx_r),1,nb_pings);
    
    Samples=repmat(idx_r',1,nb_pings);
    Ping=repmat(trans_obj.get_transceiver_pings(idx_pings),nb_samples,1);
    Time=repmat(trans_obj.get_transceiver_time(idx_pings),nb_samples,1);
    
    
    [T,Pulse_length_sample]=trans_obj.get_pulse_length(idx_pings);
    Pulse_length_sample=repmat(Pulse_length_sample,nb_samples,1);
    Np=Pulse_length_sample(1);
    T=T(1);

    
    Pulse_length_max_sample=ceil(Pulse_length_sample.*p.Results.MaxNormPL);
    Pulse_length_min_sample=floor(Pulse_length_sample.*p.Results.MinNormPL);
    
    c=nanmean(trans_obj.get_soundspeed(idx_r));

    %Calculate simradBeamCompensation
    simradBeamComp = simradBeamCompensation(BW_along, BW_athwart, along, athwart);
    
    peak_calc='TS';
    
    switch peak_calc
        case'power'
            peak_mat=Power;
        case'TS'
            peak_mat=TS;
    end

    
    switch p.Results.DataType
        case 'CW'
            
           %peak_mat=10*log10(filter2_perso(ones(floor(Np/2),1)/ceil(floor(Np/2)),10.^(peak_mat/10)));

            idx_peaks = islocalmax(peak_mat,1, 'FlatSelection', 'center','MinSeparation',Np,'MinProminence',p.Results.PLDL);

            %figure();imagesc(idx_peaks_2)
            

            idx_peaks(TS<min_TS-p.Results.MaxBeamComp|TS>max_TS)=0;
            idx_peaks_lin = find(idx_peaks);
            
%            figure();imagesc(idx_peaks,'alphadata',double(peak_mat>-56))
%            figure();imagesc(peak_mat,'alphadata',double(peak_mat>-56));caxis([-56 -30]);
            
            %Level of the local maxima (power dB)...
            
            [i_peaks_lin,j_peaks_lin] = find(idx_peaks);
            nb_peaks=length(idx_peaks_lin);
            pulse_level=peak_mat(idx_peaks_lin)-p.Results.PLDL;
            idx_samples_lin=Idx_samples_lin(idx_peaks);
            pulse_env_after_lin=zeros(nb_peaks,1);
            pulse_env_before_lin=zeros(nb_peaks,1);
            idx_sup_after=ones(nb_peaks,1);
            idx_sup_before=ones(nb_peaks,1);
            max_pulse_length=nanmax(Pulse_length_max_sample(:));
            
            
            for j=1:max_pulse_length
                idx_sup_before=idx_sup_before.*(pulse_level<=peak_mat(nanmax(i_peaks_lin-j,1)+(j_peaks_lin-1)*nb_samples));
                idx_sup_after=idx_sup_after.*(pulse_level<=peak_mat(nanmin(i_peaks_lin+j,nb_samples)+(j_peaks_lin-1)*nb_samples));
                pulse_env_before_lin=pulse_env_before_lin+idx_sup_before;
                pulse_env_after_lin=pulse_env_after_lin+idx_sup_after;
            end
            
            temp_pulse_length_sample=Pulse_length_sample(idx_peaks);
            pulse_length_lin=pulse_env_before_lin+pulse_env_after_lin+1;
            
            idx_good_pulses=(pulse_length_lin<=Pulse_length_max_sample(idx_peaks))&(pulse_length_lin>=Pulse_length_min_sample(idx_peaks));
            
            idx_target_lin=idx_peaks_lin(idx_good_pulses);
            idx_samples_lin=idx_samples_lin(idx_good_pulses);
            pulse_length_lin=pulse_length_lin(idx_good_pulses);
            pulse_length_trans_lin=temp_pulse_length_sample;
            pulse_env_before_lin=pulse_env_before_lin(idx_good_pulses);
            pulse_env_after_lin=pulse_env_after_lin(idx_good_pulses);
            
            nb_targets=length(idx_target_lin);
            
            samples_targets_sp=nan(max_pulse_length,nb_targets);
            samples_targets_power=nan(max_pulse_length,nb_targets);
            samples_targets_comp=nan(max_pulse_length,nb_targets);
            samples_targets_range=nan(max_pulse_length,nb_targets);
            samples_targets_sample=nan(max_pulse_length,nb_targets);
            samples_targets_along=nan(max_pulse_length,nb_targets);
            samples_targets_athwart=nan(max_pulse_length,nb_targets);
            samples_pulse_length_trans_samples=nan(max_pulse_length,nb_targets);
            samples_pulse_length_samples=nan(max_pulse_length,nb_targets);
            target_ping_number=nan(1,nb_targets);
            target_time=nan(1,nb_targets);
            
            if up_bar
                p.Results.load_bar_comp.progress_bar.setText('Step 1');
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_targets, 'Value',0);
            end
            
            for i=1:nb_targets
                if up_bar
                    set(p.Results.load_bar_comp.progress_bar,'Value',i);
                end
                idx_pulse=idx_target_lin(i)-pulse_env_before_lin(i):idx_target_lin(i)+pulse_env_after_lin(i);
                samples_targets_sp(1:pulse_length_lin(i),i)=TS(idx_pulse);
                samples_targets_power(1:pulse_length_lin(i),i)=Power(idx_pulse);
                samples_targets_comp(1:pulse_length_lin(i),i)=simradBeamComp(idx_pulse);
                samples_targets_range(1:pulse_length_lin(i),i)=Range(idx_pulse);
                samples_targets_sample(1:pulse_length_lin(i),i)=Samples(idx_pulse);
                samples_targets_along(1:pulse_length_lin(i),i)=along(idx_pulse);
                samples_targets_athwart(1:pulse_length_lin(i),i)=athwart(idx_pulse);
                samples_pulse_length_trans_samples(1:pulse_length_lin(i),i)=pulse_length_trans_lin(i);
                samples_pulse_length_samples(1:pulse_length_lin(i),i)=pulse_length_lin(i);
                target_ping_number(i)=Ping(idx_target_lin(i));
                target_time(i)=Time(idx_target_lin(i));
            end
            
            [~,idx_peak_power]=nanmax(samples_targets_power);
            
            target_comp=samples_targets_comp(idx_peak_power+(0:nb_targets-1)*max_pulse_length);
            samples_targets_idx_r=nanmin(samples_targets_sample)+idx_peak_power-1;
            power_norm= nansum(samples_targets_power)./nanmax(samples_targets_power);
            
            std_along=nanstd(samples_targets_along);
            std_athwart=nanstd(samples_targets_athwart);
                
            idx_rem=std_along>p.Results.MaxStdMinAxisAngle|std_athwart>p.Results.MaxStdMajAxisAngle;
            
            samples_targets_sp(:,idx_rem)=nan; 
            
            samples_targets_power(:,idx_rem)=nan;
            samples_targets_range(:,idx_rem)=nan;

            dr=double(c*T/Np);
            
            target_range=nansum(samples_targets_power.*samples_targets_range)./nansum(samples_targets_power)-dr;
            
            target_range(target_range<0)=0;
            
            target_range_min=nanmin(samples_targets_range);
            target_range_max=nanmax(samples_targets_range);
            
            target_TS_uncomp=samples_targets_sp(idx_peak_power+(0:nb_targets-1)*max_pulse_length);
            phi_along=samples_targets_along(idx_peak_power+(0:nb_targets-1)*max_pulse_length);
            phi_athwart=samples_targets_athwart(idx_peak_power+(0:nb_targets-1)*max_pulse_length);
            
            target_TS_comp=target_TS_uncomp+target_comp;
            target_TS_comp(target_TS_comp<min_TS|target_comp>p.Results.MaxBeamComp|target_TS_comp>max_TS)=nan;
            target_TS_uncomp(target_TS_comp<min_TS|target_comp>p.Results.MaxBeamComp|target_TS_comp>max_TS)=nan;
            
            %removing all non-valid_targets again...
            idx_keep= ~isnan(target_TS_comp);
            %pulse_length_lin=pulse_length_lin(idx_keep);
            pulse_length_trans_lin=pulse_length_trans_lin(idx_keep);
            target_TS_comp=target_TS_comp(idx_keep);
            target_TS_uncomp=target_TS_uncomp(idx_keep);
            target_range=target_range(idx_keep);
            target_range_min=target_range_min(idx_keep);
            target_range_max=target_range_max(idx_keep);
            target_idx_r=samples_targets_idx_r(idx_keep);
            std_along=std_along(idx_keep);
            std_athwart=std_athwart(idx_keep);
            phi_along=phi_along(idx_keep);
            phi_athwart=phi_athwart(idx_keep);
            target_ping_number=target_ping_number(idx_keep);
            target_time=target_time(idx_keep);
            nb_valid_targets=nansum(idx_keep);
            idx_target_lin=idx_target_lin(idx_keep);
            idx_samples_lin=idx_samples_lin(idx_keep);
            pulse_env_before_lin=pulse_env_before_lin(idx_keep);
            pulse_env_after_lin=pulse_env_after_lin(idx_keep);
            
            %let's remove overlapping targets just in case...
            idx_target=zeros(nb_samples,nb_pings);
            if up_bar
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_valid_targets, 'Value',0);
                p.Results.load_bar_comp.progress_bar.setText('Step 2');
            end
            for i=1:nb_valid_targets
                
                    if up_bar
                        set(p.Results.load_bar_comp.progress_bar,'Value',i);
                    end
                
                idx_same_ping=find(target_ping_number==target_ping_number(i));
                
                same_target=find((target_range_max(idx_same_ping)==target_range_max(i)&(target_range_min(i)==target_range_min(idx_same_ping))));
                
                if  length(same_target)>=2
                    target_TS_comp(idx_same_ping(same_target(2:end)))=nan;
                    target_range_max(idx_same_ping(same_target(2:end)))=nan;
                    target_range_min(idx_same_ping(same_target(2:end)))=nan;
                end
                
                overlapping_target=(target_range(idx_same_ping)<=target_range_max(i)&(target_range_min(i)<=target_range(idx_same_ping)))|...
                    (target_range_max(idx_same_ping)<=target_range_max(i)&(target_range_min(i)<=target_range_max(idx_same_ping)))|...
                    (target_range_min(idx_same_ping)<=target_range_max(i)&(target_range_min(i)<=target_range_min(idx_same_ping)));
                
                idx_target(idx_target_lin(i)-pulse_env_before_lin(i):idx_target_lin(i)+pulse_env_after_lin(i))=1;
                
                if nansum(overlapping_target)>=2
                    idx_overlap=target_TS_comp(idx_same_ping(overlapping_target))<nanmax(target_TS_comp(idx_same_ping(overlapping_target)));
                    target_TS_comp(idx_same_ping(idx_overlap))=nan;
                    target_range_max(idx_same_ping(idx_overlap))=nan;
                    target_range_min(idx_same_ping(idx_overlap))=nan;
                end
            end
            
            
            
            
            %removing all non-valid_targets again an storing results in single target
            %structure...
            idx_keep_final= ~isnan(target_TS_comp);
            single_targets.Power_norm=power_norm(idx_keep_final);
            single_targets.TS_comp=target_TS_comp(idx_keep_final);
            single_targets.TS_uncomp=target_TS_uncomp(idx_keep_final);
            single_targets.Target_range=target_range(idx_keep_final);
            single_targets.Target_range_disp=target_range(idx_keep_final)+2*dr;
            single_targets.idx_r=target_idx_r(idx_keep_final);
            single_targets.Target_range_min=target_range_min(idx_keep_final);
            single_targets.Target_range_max=target_range_max(idx_keep_final);
            single_targets.StandDev_Angles_Minor_Axis=std_along(idx_keep_final);
            single_targets.StandDev_Angles_Major_Axis=std_athwart(idx_keep_final);
            single_targets.Angle_minor_axis=phi_along(idx_keep_final);
            single_targets.Angle_major_axis=phi_athwart(idx_keep_final);
            single_targets.Ping_number=target_ping_number(idx_keep_final);
            single_targets.Time=target_time(idx_keep_final);
            
            idx_target_lin=idx_target_lin(idx_keep_final)';
            single_targets.idx_target_lin=idx_samples_lin(idx_keep_final)';
            single_targets.pulse_env_before_lin=pulse_env_before_lin(idx_keep_final)';
            single_targets.pulse_env_after_lin=pulse_env_after_lin(idx_keep_final)';
            single_targets.TargetLength = (pulse_env_after_lin(idx_keep_final)'+pulse_env_before_lin(idx_keep_final)'+1);
            single_targets.PulseLength_Normalized_PLDL=(pulse_env_after_lin(idx_keep_final)'+pulse_env_before_lin(idx_keep_final)'+1)./pulse_length_trans_lin(idx_keep_final)';
            single_targets.Transmitted_pulse_length=T*ones(size(single_targets.PulseLength_Normalized_PLDL));
            
            
            heading_mat=repmat(heading(idx_pings),nb_samples,1);
            roll_mat=repmat(roll(idx_pings),nb_samples,1);
            pitch_mat=repmat(pitch(idx_pings),nb_samples,1);
            heave_mat=repmat(heave(idx_pings),nb_samples,1);
            dist_mat=repmat(dist(idx_pings),nb_samples,1);
            yaw_mat=repmat(yaw(idx_pings),nb_samples,1);
            
            single_targets.Dist=dist_mat(idx_target_lin);
            single_targets.Roll=roll_mat(idx_target_lin);
            single_targets.Pitch=pitch_mat(idx_target_lin);
            single_targets.Yaw=yaw_mat(idx_target_lin);
            single_targets.Heave=heave_mat(idx_target_lin);
            single_targets.Heading=heading_mat(idx_target_lin);
            
            single_targets.Track_ID=nan(size(single_targets.Heading));
            
                 
            
        case 'FM'
            dt=trans_obj.get_params_value('SampleInterval',idx_pings(1));
            dr=dt*nanmean(trans_obj.get_soundspeed(idx_r))/2;
   
            [T,Np_t]=trans_obj.get_pulse_Teff(idx_pings(1));
            T=T/4;
            Np_t=ceil(Np_t/4);
            
            peak_mat(peak_mat==-999)=nan;
%             tic;
%             peak_mat_cell=mat2cell(peak_mat,size(peak_mat,1),ones(1,size(peak_mat,2)));
%             [~,idx_peaks_lin_cell,width_peaks_cell,~]=cellfun(@(x) findpeaks(x,...
%                 'MinPeakHeight',min_TS-p.Results.MaxBeamComp,...
%                 'WidthReference','halfprom',...
%                 'MinPeakDistance',(p.Results.MaxNormPL*Np_t),...
%                 'MinPeakWidth',(p.Results.MinNormPL*Np_t*2),...
%                 'MaxPeakWidth',(p.Results.MaxNormPL*Np_t*3)),peak_mat_cell,'un',0);
%             
%             toc
%             tic
%             
            [~,idx_peaks_lin,width_peaks ,~] = findpeaks(peak_mat(:),...
                'MinPeakHeight',min_TS-p.Results.MaxBeamComp,...
                'WidthReference','halfprom',...
                'MinPeakDistance',(p.Results.MaxNormPL*Np_t),...
                'MinPeakWidth',(p.Results.MinNormPL*Np_t*2),...
                'MaxPeakWidth',(p.Results.MaxNormPL*Np_t*3));
            %toc
            %figure();plot(peak_mat(:));hold on;plot(idx_peaks_lin,peak_vals,'+');xlim([1 1e4])
%             
%             figure();findpeaks(peak_mat(:),...
%                 'MinPeakHeight',min_TS-p.Results.MaxBeamComp,...
%                 'MinPeakDistance',T/dt,...
%                 'MinPeakProminence',p.Results.PLDL,...
%                 'MinPeakWidth',(p.Results.MinNormPL*Np_t)*5,...
%                 'MaxPeakWidth',(p.Results.MaxNormPL*Np_t)*15);
            
            comp=simradBeamComp(idx_peaks_lin);
            idx_rem=comp>p.Results.MaxBeamComp;
            idx_peaks_lin(idx_rem)=[];
            width_peaks(idx_rem)=[];
            
            idx_samples_lin=Idx_samples_lin(idx_peaks_lin);
                        
            idx_samples=rem(idx_peaks_lin,size(peak_mat,1));
            idx_samples(idx_samples==0)=nb_samples;

            idx_pings=Ping(idx_peaks_lin);

  
            
            single_targets.TS_comp=TS(idx_peaks_lin)'+simradBeamComp(idx_peaks_lin)';
            single_targets.TS_uncomp=TS(idx_peaks_lin)';
            single_targets.Target_range=Range(idx_peaks_lin)';
            single_targets.Target_range_disp=Range(idx_peaks_lin)'+c*T/2;
            single_targets.idx_r= (idx_r_tot(idx_samples)+idx_r_min-1)';
            single_targets.Target_range_min=Range(idx_peaks_lin)'-width_peaks'/2*dr;
            single_targets.Target_range_max=Range(idx_peaks_lin)'-width_peaks'/2*dr;
            single_targets.StandDev_Angles_Minor_Axis=zeros(size(idx_peaks_lin))';
            single_targets.StandDev_Angles_Major_Axis=zeros(size(idx_peaks_lin))';
            single_targets.Angle_minor_axis=along(idx_peaks_lin)';
            single_targets.Angle_major_axis=athwart(idx_peaks_lin)';
            single_targets.Ping_number=idx_pings';
            single_targets.Time=Time(idx_pings)';
            
            single_targets.idx_target_lin=idx_samples_lin;
            single_targets.pulse_env_before_lin=width_peaks'/2*dt;
            single_targets.pulse_env_after_lin=width_peaks'/2*dt;
            single_targets.Transmitted_pulse_length=T*ones(size(idx_peaks_lin'));
            
            single_targets.PulseLength_Normalized_PLDL=width_peaks';
            single_targets.TargetLength=width_peaks';
            single_targets.Power_norm=zeros(size(single_targets.TargetLength));  
            single_targets.Dist=dist(single_targets.Ping_number);
            single_targets.Roll=roll(single_targets.Ping_number);
            single_targets.Pitch=pitch(single_targets.Ping_number);
            single_targets.Yaw=yaw(single_targets.Ping_number);
            single_targets.Heave=heave(single_targets.Ping_number);
            single_targets.Heading=heading(single_targets.Ping_number);
            single_targets.Track_ID=nan(size(idx_peaks_lin))';
            
            
    end
    
    if ~isempty(single_targets.Ping_number)
        bot_range=trans_obj.get_bottom_range(single_targets.Ping_number);
        single_targets.Target_range_to_bottom=bot_range-single_targets.Target_range;
    end
    
    fields_st=fieldnames(single_targets);
    for ifi=1:numel(fields_st)
        single_targets.(fields_st{ifi})=single_targets.(fields_st{ifi})(:)';
    end
    if ui>1  
        
        for ifi=1:numel(fields_st)
            single_targets_tot.(fields_st{ifi})=cat(2,single_targets_tot.(fields_st{ifi}),single_targets.(fields_st{ifi}));
        end
    else
        fields_st=fieldnames(single_targets);
        for ifi=1:numel(fields_st)
            single_targets_tot.(fields_st{ifi})= single_targets.(fields_st{ifi});
        end
    end
    if up_bar
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',ui);
    end
    
end

output_struct.single_targets=single_targets_tot;

if ~isempty(output_struct.single_targets)
    trans_obj.set_ST(output_struct.single_targets);
end
output_struct.done =  true;
%old_single_targets=trans_obj.ST;

% if~isempty(old_single_targets)
%     if ~isempty(old_single_targets.TS_comp)
%
%         idx_rem=(old_single_targets.idx_r>=idx_r(1)&old_single_targets.idx_r<=idx_r(end))&(old_single_targets.Ping_number>=idx_pings(1)&old_single_targets.Ping_number<=idx_pings(end));
%
%         props=fields(old_single_targets);
%
%         for i=1:length(props)
%             if length(old_single_targets.(props{i}))==length(idx_rem)
%             old_single_targets.(props{i})(idx_rem)=[];
%             single_targets.(props{i})=[old_single_targets.(props{i})(:)' single_targets.(props{i})(:)'];
%             end
%         end
%     end
%
% end
% profile off;
% profile viewer;
