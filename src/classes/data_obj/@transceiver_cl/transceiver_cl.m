
classdef transceiver_cl < handle
    
    properties
        
        Data = ac_data_cl.empty();
        Range
        Alpha
        Alpha_ori = 'constant'
        Time
        Bottom
        ST
        Tracks
        Regions
        Params = params_cl();
        Config = config_cl();
        Filters
        GPSDataPing
        AttitudeNavPing
        Algo = algo_cl.empty();
        Mode
        TransducerImpedance={};
        TransducerDepth double
        Spikes
    end
    
    methods
        
        %% constructor %%
        function trans_obj = transceiver_cl(varargin)
            
            p = inputParser;
            addParameter(p,'Data', ac_data_cl.empty(), @(x) isa(x,'ac_data_cl'));
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'TransducerDepth',[],@isnumeric);
            addParameter(p,'TransducerImpedance',{},@(x) iscell(x)||isempty(x));
            addParameter(p,'Range',[],@isnumeric);
            addParameter(p,'Alpha',[],@isnumeric);
            addParameter(p,'Alpha_ori','constant',@(x) ismember(x,{'constant' 'profile' 'theoritical'}));
            addParameter(p,'Bottom',bottom_cl(),@(x) isa(x,'bottom_cl'));
            addParameter(p,'ST',init_st_struct(),@isstruct);
            addParameter(p,'Tracks',struct('target_id',{},'target_ping_number',{},'uid',{},'id',[]),@isstruct);
            addParameter(p,'Regions',region_cl.empty(),@(x) isa(x,'region_cl'));
            addParameter(p,'Params',params_cl(),@(x) isa(x,'params_cl'));
            addParameter(p,'Config',config_cl(),@(x) isa(x,'config_cl'));
            addParameter(p,'Filters',filter_cl.empty(),@(x) isa(x,'filter_cl'));
            addParameter(p,'GPSDataPing',gps_data_cl.empty(),@(x) isa(x,'gps_data_cl'));
            addParameter(p,'AttitudeNavPing',attitude_nav_cl.empty(),@(x) isa(x,'attitude_nav_cl'));
            addParameter(p,'Algo',algo_cl.empty(),@(x) isa(x,'algo_cl')||isempty(x));
            addParameter(p,'ComputeImpedance',false,@islogical);
            addParameter(p,'Mode','CW',@ischar);
            
            parse(p,varargin{:});
            results = p.Results;
            props = fieldnames(results);
            
            
            
            for i = 1:length(props)
                if isprop(trans_obj,props{i})
                    trans_obj.(props{i}) = results.(props{i});
                end
            end
            
            if ~isempty(p.Results.Data)
                if isempty(p.Results.GPSDataPing)
                    trans_obj.GPSDataPing = gps_data_cl('Time',p.Results.Time);
                end
                if isempty(p.Results.AttitudeNavPing)
                    trans_obj.AttitudeNavPing = attitude_nav_cl('Time',p.Results.Time);
                end
            end
            
            if isempty(trans_obj.TransducerDepth)
                trans_obj.TransducerDepth=zeros(size(trans_obj.Time));
            end
            
            if isempty(trans_obj.TransducerImpedance)&&p.Results.ComputeImpedance
                trans_obj.TransducerImpedance=cell(size(trans_obj.Time));
            else
                trans_obj.TransducerImpedance = [];
            end
            
            trans_obj.Params=trans_obj.Params.reduce_params();
            trans_obj.Bottom = p.Results.Bottom;
            if ~isempty(trans_obj.Params.PingNumber)
                trans_obj.set_pulse_Teff();
                trans_obj.set_pulse_comp_Teff();
            end
            trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));
            
        end
        
        function p_out = get_params_value(trans_obj,param_name,idx)
            
            nb_pings = numel(trans_obj.Time);
            
            if nb_pings == 0
                nb_pings = 1;
            end
            
            if isempty(idx)
                idx=1:nb_pings;
            end
            
            if numel(trans_obj.Params.(param_name))==nb_pings
                p_out = trans_obj.Params.(param_name)(idx);
            else
                idx(idx<1|idx>nb_pings) = [];
                
                mat_diff=idx-double(trans_obj.Params.PingNumber');
                mat_diff(mat_diff<0)=inf;
                
                [~,id]=nanmin(mat_diff,[],1);
                p_out = trans_obj.Params.(param_name)(id);
            end
        end
        
        function mask_spikes = get_spikes(trans_obj,idx_r,idx_pings)
            if isempty(trans_obj.Spikes)
                trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));
            end
            
            if isempty(idx_r)
                idx_r=1:numel(trans_obj.Range);
            end
            
            if isempty(idx_pings)
                idx_pings=1:numel(trans_obj.Time);
            end
            mask_spikes=trans_obj.Spikes(idx_r,idx_pings);
            
        end
        
        function set_spikes(trans_obj,idx_r,idx_pings,mask)
            
            if ~issparse(trans_obj.Spikes)
                trans_obj.Spikes=sparse(trans_obj.Spikes);
            end
            
            if isempty(trans_obj.Spikes)
                trans_obj.Spikes=sparse(numel(trans_obj.Range),numel(trans_obj.Time));
            end
            
            if isscalar(mask)&&isempty(idx_r)
                idx_r=1:numel(trans_obj.Range);
            elseif ~isscalar(mask)&&isempty(idx_r)
                idx_r=1:size(mask,1);
            end
            
            if isscalar(mask)&&isempty(idx_pings)
                idx_pings=1:numel(trans_obj.Time);
            elseif ~isscalar(mask)&&isempty(idx_pings)
                idx_pings=1:size(mask,1);
            end
            
            trans_obj.Spikes(idx_r,idx_pings) = sparse(mask);
            
        end
        
        
        
        %% set Bottom property %%
        function set.Bottom(obj,bottom_obj)
            
            if isempty(bottom_obj)
                bottom_obj = bottom_cl();
            end
            
            % indices of bad pings in the new bottom object
            IdxBad = find(bottom_obj.Tag==0);
            IdxBad(IdxBad<=0) = [];
            
            % get the bottom sample index in the new bottom object
            bot_sple = bottom_obj.Sample_idx;
            bot_sple(bot_sple<1) = 1;
            
            % size of channel
            samples = obj.get_transceiver_samples();
            pings   = obj.get_transceiver_pings();
            
            % initialize new bot_sple
            new_bot_sple = nan(size(pings));
            
            if ~isempty(bot_sple)
                
                % not quite sure what this does. Looks like it's a case
                % when the new bottom object doesn't have the same size as
                % the channel data?
                i0 = abs(length(bot_sple)-length(pings));
                if length(bot_sple) > length(pings)
                    new_bot_sple(i0:end) = bot_sple(1:end-(i0+1));
                    IdxBad = IdxBad+i0;
                elseif length(bot_sple) < length(pings)
                    new_bot_sple(1+i0:i0+length(bot_sple)) = bot_sple;
                    IdxBad = IdxBad+i0;
                else
                    new_bot_sple = bot_sple;
                end
                while nanmax(IdxBad) > length(pings)
                    IdxBad = IdxBad-1;
                end
                
                % at the end, ensure max of bottom sample is the last
                % value available and min is 1
                new_bot_sple(new_bot_sple>length(samples)) = length(samples);
                new_bot_sple(new_bot_sple<=0) = 1;
            end
            
            % create new bad pings vector
            tag = ones(size(new_bot_sple));
            tag(IdxBad) = 0;
            
            % wherever there is no bottom or the ping is bad, set the
            % bottom at the last sample
            new_bot_sple(isnan(new_bot_sple(:))&tag(:)==1) = length(samples);
            
            %             if ~isempty(obj.Bottom)
            %                 old_bot_sple=obj.Bottom.Sample_idx;
            %             else
            %                 old_bot_sple=[];
            %             end
            
            %             if all(size(new_bot_sple)==size(old_bot_sple))
            %                 idx_pings_mod=find((new_bot_sple~=old_bot_sple)&~(isnan(new_bot_sple)&isnan(old_bot_sple)));
            %             else
            %                 idx_pings_mod=pings;
            %             end
            
            % setting E1
            if isempty(new_bot_sple)
                % brand new bottom object
                E1 = [];
            else
                % get the old and new values
                if isprop(obj,'Bottom')
                    old_E1 = obj.Bottom.E1;
                else
                    old_E1 = [];
                end
                
                new_E1 = bottom_obj.E1;
                E1 = old_E1;
                
                if isempty(E1) || ~all(size(E1)==size(new_bot_sple))
                    % no data either old or new, initialize E1
                    E1 = -999.*ones(size(new_bot_sple));
                    %idx_pings_mod = pings;
                end
                
                if ~isempty(new_E1) && all(size(new_E1)==size(new_bot_sple))
                    E1 = new_E1;
                end
                
            end
            
            
            % setting E2
            if isempty(new_bot_sple)
                % brand new bottom object
                E2 = [];
            else
                
                % get the old and new values
                if isprop(obj,'Bottom')
                    old_E2 = obj.Bottom.E2;
                else
                    old_E2 = [];
                end
                
                new_E2 = bottom_obj.E2;
                E2 = old_E2;
                
                if isempty(E2) || ~all(size(E2)==size(new_bot_sple))
                    % no data either old or new, initialize E2
                    E2 = -999.*ones(size(new_bot_sple));
                    %idx_pings_mod = pings;
                end
                
                if ~isempty(new_E2) && all(size(new_E2)==size(new_bot_sple))
                    E2 = new_E2;
                end
                
            end
            %                  E1(IdxBad)=-999;
            %                  E2(IdxBad)=-999;
            % create the bottom object and add to trans object
            obj.Bottom = bottom_cl('Origin',bottom_obj.Origin(:)',...
                'Sample_idx',new_bot_sple(:)',...
                'E1',E1,...
                'E2',E2,...
                'Tag',tag(:)',...
                'Version',bottom_obj.Version);
            
            
            %             if ~isempty(idx_pings_mod)
            % %                 profile on;
            %                 obj.apply_algo('BottomFeatures','reg_obj',region_cl('Idx_pings',idx_pings_mod,'Idx_r',[1 10]));
            % %                 profile off;
            % %                 profile viewer;
            %             end
            
        end
        
        function f_c=get_center_frequency(trans_obj)
            
            switch trans_obj.Mode
                case 'FM'
                    f_c=(trans_obj.get_params_value('FrequencyStart',[])+trans_obj.get_params_value('FrequencyEnd',[]))/2;
                case 'CW'
                    f_c=trans_obj.get_params_value('Frequency',[]);
                otherwise
                    f_c=trans_obj.get_params_value('Frequency',[]);
            end
            
        end
        
        function rm_ST(trans_obj)
            trans_tmp=transceiver_cl();
            trans_obj.ST=trans_tmp.ST;
        end
        
        function delete(trans_obj)
            if ~isdeployed
                c = class(trans_obj);
                disp(['ML trans_object destructor called for class ',c])
            end
        end
        
        function range = get_transceiver_range(trans_obj,varargin)
            if nargin>=2
                idx = varargin{1};
                if ~isempty(idx)
                    range = trans_obj.Range(idx);
                else
                    range = trans_obj.Range;
                end
            else
                range = trans_obj.Range;
            end
            
        end
        
        
        function depth=get_transceiver_depth(trans_obj,idx_r,idx_pings)
            t_angle=trans_obj.get_transducer_pointing_angle();
            depth=bsxfun(@plus,trans_obj.get_transceiver_range(idx_r)*sin(t_angle),trans_obj.get_transducer_depth(idx_pings));
        end
        
        function t_angle=get_transducer_pointing_angle(trans_obj)
            t_angle=pi/2-atan(sqrt(tand(trans_obj.Config.TransducerAlphaX) .^2 + tand(trans_obj.Config.TransducerAlphaY) .^2));
        end
        
        function depth=get_transducer_depth(trans_obj,varargin)
            depth=trans_obj.TransducerDepth(:)';
            
            if nargin>=2
                idx=varargin{1};
                idx(idx<1)=1;
                idx(idx>=numel(depth))=numel(depth);
                if ~isempty(idx)
                    depth=depth(idx);
                end
            end
        end
        
        function heave=get_transducer_heave(trans_obj,varargin)
            heave=trans_obj.AttitudeNavPing.Heave(:)';
            
            if nargin>=2
                idx=varargin{1};
                idx(idx<1)=1;
                idx(idx>=numel(heave))=numel(heave);
                if ~isempty(idx)
                    heave=heave(idx);
                end
            end
            heave(isnan(heave))=0;
        end
        
        function set.Range(trans_obj,r)
            trans_obj.Range=r(:);
        end
        
        function set.Time(trans_obj,t)
            trans_obj.Time=t(:)';
        end
        
        function set_transceiver_range(trans_obj,range)
            trans_obj.Range=range(:);
        end
        
        function set_transceiver_time(trans_obj,time)
            trans_obj.Time=time(:)';
        end
        
        function samples=get_transceiver_samples(trans_obj,varargin)
            if ~isempty(trans_obj.Data)
                samples=(1:nanmax(trans_obj.Data.Nb_samples))';
                if nargin>=2
                    idx=varargin{1};
                    samples=samples(idx);
                end
            else
                samples=[];
            end
            
        end
        
        function time_r=get_transceiver_time_r(trans_obj,idx_r)
            if ~isempty(idx_r)
                s=trans_obj.get_transceiver_samples();
            else
                s=trans_obj.get_transceiver_samples(idx_r);
            end
            
            si=trans_obj.get_params_value('SampleInterval',1);
            
            time_r=(s-1)./si;
            
        end
        
        function time=get_transceiver_time(trans_obj,varargin)
            time=trans_obj.Time;
            if nargin>=2
                idx=varargin{1};
                time=time(idx);
            end
        end
        
        
        function pings=get_transceiver_pings(trans_obj,varargin)
            if ~isempty(trans_obj.Data)
                pings=(1:trans_obj.Data.Nb_pings);
                if nargin>=2
                    idx=varargin{1};
                    pings=pings(idx);
                end
            else
                pings=[];
            end
        end
        
        
        function list=regions_to_str(trans_obj)
            if isempty(trans_obj.Regions)
                list={};
            else
                list=cell(1,length(trans_obj.Regions));
                for i=1:length(trans_obj.Regions)
                    new_name=sprintf('%s %0.f %s',trans_obj.Regions(i).Name,trans_obj.Regions(i).ID,trans_obj.Regions(i).Type);
                    u=1;
                    new_name_ori=new_name;
                    while nansum(strcmpi(new_name,list))>=1
                        new_name=[new_name_ori '_' num2str(u)];
                        u=u+1;
                    end
                    list{i}=new_name;
                end
            end
        end
        
        function idx=find_regions_origin(trans_obj,origin)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmp({trans_obj.Regions(:).Origin},origin));
            end
        end
        
        
        function idx=find_regions_type(trans_obj,type)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmpi({trans_obj.Regions(:).Type},type));
            end
        end
        
        
        function idx=find_regions_tag(trans_obj,tags)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember({trans_obj.Regions(:).Tag},tags));
            end
        end
        
        function tags=get_reg_tags(trans_obj)
            if isempty(trans_obj.Regions)
                tags={};
            else
                
                tags=unique({trans_obj.Regions(:).Tag});
            end
        end
        
        function IDs=get_reg_IDs(trans_obj)
            if isempty(trans_obj.Regions)
                IDs=[];
            else
                IDs=[trans_obj.Regions(:).ID];
            end
        end
        
        
        function IDs=get_reg_Unique_IDs(trans_obj)
            if isempty(trans_obj.Regions)
                IDs={};
            else
                IDs={trans_obj.Regions(:).Unique_ID};
            end
        end
        
        function IDs=get_reg_first_Unique_ID(trans_obj)
            if isempty(trans_obj.Regions)
                IDs={};
            else
                IDs=trans_obj.Regions(1).Unique_ID;
            end
        end
        
        function fileID=get_fileID(trans_obj)
            fileID=trans_obj.Data.FileId;
        end
        
        function bID=get_blockID(trans_obj)
            bID=trans_obj.Data.blockId;
        end
        
        
        function idx=find_regions_ID(trans_obj,ID)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember([trans_obj.Regions(:).ID],ID));
            end
        end
        
        function idx=find_regions_Unique_ID(trans_obj,ID)
            if~iscell(ID)
                ID={ID};
            end
            if isempty(trans_obj.Regions)||isempty(ID)
                idx=[];
            else
                reg_uids={trans_obj.Regions(:).Unique_ID};
                idx=cellfun(@(x) find(strcmpi(x,reg_uids)),ID,'un',0);
                idx(cellfun(@isempty,idx))=[];
                if ~isempty(idx)
                    idx=cell2mat(idx);
                else
                    idx=[];
                end
                
            end
        end
        function reg=get_region_from_name(trans_obj,names)
            idx=trans_obj.find_regions_name(names);
            if ~isempty(idx)
                reg=trans_obj.Regions(idx);
            else
                reg=[];
            end
        end
        
        
        function reg=get_region_from_Unique_ID(trans_obj,ID)
            idx=trans_obj.find_regions_Unique_ID(ID);
            if ~isempty(idx)
                reg=trans_obj.Regions(idx);
            else
                reg=region_cl.empty();
            end
        end
        
        function idx=find_regions_ref(trans_obj,Reference)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(strcmpi({trans_obj.Regions(:).Reference},Reference));
            end
        end
        
        function idx=find_regions_name(trans_obj,names)
            if isempty(trans_obj.Regions)
                idx=[];
            else
                idx=find(ismember(lower({trans_obj.Regions(:).Name}),lower(names)));
            end
        end
        
        function rm_all_region(trans_obj)
            trans_obj.Regions=[];
        end
        
        function rm_tracks(trans_obj)
            trans_tmp=transceiver_cl();
            trans_obj.Tracks=trans_tmp.Tracks;
        end
        
        
        
        function rm_region_name(trans_obj,name)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Name},name);
                trans_obj.Regions(idx)=[];
            end
        end
        
        function rm_region_name_idx_r_idx_p(trans_obj,name,idx_r,idx_p)
            reg_curr=trans_obj.Regions;
            reg_new=[];
            for i=1:length(reg_curr)
                if ~strcmpi(reg_curr(i).Name,name)||(isempty(intersect(idx_r,reg_curr(i).Idx_r))&&~isempty(idx_r))||(isempty(intersect(idx_p,reg_curr(i).Idx_pings))&&~isempty(idx_p))%TODO
                    reg_new=[reg_new reg_curr(i)];
                end
            end
            trans_obj.Regions=reg_new;
        end
        
        
        
        function rm_regions(trans_obj)
            trans_obj.Regions=[];
        end
        
        function rm_region_name_id(trans_obj,name,ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Name},name)&([trans_obj.Regions(:).ID]==ID);
                trans_obj.Regions(idx)=[];
            end
        end
        
        function rm_region_type_id(trans_obj,type,ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Type},type)&([trans_obj.Regions(:).ID]==ID);
                trans_obj.Regions(idx)=[];
            end
        end
        
        function rm_region_id(trans_obj,unique_ID)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Unique_ID},unique_ID);
                trans_obj.Regions(idx)=[];
            end
            
            
        end
        
        function rm_region_origin(trans_obj,origin)
            if ~isempty(trans_obj.Regions)
                idx=strcmpi({trans_obj.Regions(:).Origin},origin);
                trans_obj.Regions(idx)=[];
            end
        end
        
        
        
        function id=new_id(trans_obj)
            reg_curr=trans_obj.Regions;
            
            if ~isempty(reg_curr)
                id_list=[reg_curr(:).ID];
            else
                id_list=[];
            end
            if~isempty(id_list)
                new_id=setdiff(1:nanmax(id_list)+1,id_list);
                id=new_id(1);
            else
                id=1;
            end
        end
        
        function [idx,found]=find_reg_idx(trans_obj,unique_ID)
            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Unique_ID},unique_ID));
            else
                idx=[];
            end
            
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end
            
            if length(idx)>1
                warning('several regions with the same ID')
            end
            
        end
        
        function [idx,found]=find_reg_name(trans_obj,name)
            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Name},name));
            else
                idx=[];
            end
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end
            
        end
        
        function [idx,found]=find_reg_name_id(trans_obj,name,ID)
            if ~isempty(trans_obj.Regions)
                idx=find(strcmpi({trans_obj.Regions(:).Name},name)&([trans_obj.Regions(:).ID]==ID));
            else
                idx=[];
            end
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end
            
        end
        
        
        function [idx,found]=find_reg_idx_id(trans_obj,ID)
            idx=strcmpi({trans_obj.Regions(:).Name},name)&([trans_obj.Regions(:).ID]==ID);
            
            if isempty(idx)
                idx=1;
                found=0;
            else
                found=1;
            end
            
        end
        
        %% get mean depth per ping in region
        function [mean_depth,Sa] = get_mean_depth_from_region(trans_obj,unique_id)
            
            % get active region
            [reg_idx,found] = trans_obj.find_reg_idx(unique_id);
            if found == 0
                mean_depth = [];
                Sa = [];
                return;
            end
            active_reg = trans_obj.Regions(reg_idx);
            
            % get data from region
            [Sv,idx_r,~,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,active_reg,...
                'field','sv');
            
            % combine masks and apply to Sv
            Mask_reg = ~bad_data_mask & intersection_mask & ~mask_from_st & ~isnan(Sv) & ~below_bot_mask;
            Mask_reg(:,bad_trans_vec) = false;
            Sv(Sv<-90) = -999;
            Sv(~Mask_reg) = nan;
            
            % calculate mean depth
            range = double(trans_obj.get_transceiver_range(idx_r));
            mean_depth = nansum(10.^(Sv/20).*repmat(range,1,size(Sv,2)))./nansum(10.^(Sv/20));
            
            % calculate Sa
            Sa = 10*log10(nansum(10.^(Sv/10).*nanmean(diff(range))));
            
            % remove depth where Sa too low
            mean_depth(Sa<-90) = NaN;
            
        end
        
        function [BW_al,BW_at] = get_beamwidth_at_f_c(trans_obj,cal_struct)
            f_c = nanmean(trans_obj.get_center_frequency());
            if isempty(cal_struct)
                [cal_struct,~]=trans_obj.get_fm_cal('verbose',false);
            end
            [~,idx] = nanmin(abs(cal_struct.Frequency-f_c));
            BW_al = cal_struct.BeamWidthAlongship(idx);
            BW_at = cal_struct.BeamWidthAthwartship(idx);
        end
        
        %% Set transducer position
        function set_position(trans_obj,pos_trans,trans_angle)
            trans_obj.Config.TransducerOffsetX=pos_trans(1);
            trans_obj.Config.TransducerOffsetY=pos_trans(2);
            trans_obj.Config.TransducerOffsetZ=pos_trans(3);
            trans_obj.Config.TransducerAlphaX=trans_angle(1);
            trans_obj.Config.TransducerAlphaY=trans_angle(2);
            trans_obj.Config.TransducerAlphaZ=trans_angle(3);
        end
        
        function pos_trans=get_position(trans_obj)
            pos_trans=nan(3,1);
            pos_trans(1)= trans_obj.Config.TransducerOffsetX;
            pos_trans(2)= trans_obj.Config.TransducerOffsetY;
            pos_trans(3)= trans_obj.Config.TransducerOffsetZ;
        end
        
        function trans_angle=get_angles(trans_obj)
            trans_angle(1)=trans_obj.Config.TransducerAlphaX;
            trans_angle(2)=trans_obj.Config.TransducerAlphaY;
            trans_angle(3)=trans_obj.Config.TransducerAlphaZ;
        end
        
    end
    
    
end

