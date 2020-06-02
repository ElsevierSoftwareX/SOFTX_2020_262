function [TS_f,f_vec,pings,r_tot]=TS_f_from_region(trans_obj,reg_obj,varargin)

p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'reg_obj',@(x) isa(x,'region_cl')||isstruct(x));
addParameter(p,'envdata',env_data_cl,@(x) isa(x,'env_data_cl'));
addParameter(p,'cal',[],@(x) isempty(x)|isstruct(x));
addParameter(p,'att_model','doonan',@(s) ismember(s,{'fandg' 'doonan'}));
addParameter(p,'mode','max_reg',@(s) ismember(s,{'max_reg' 'mat'}));
addParameter(p,'load_bar_comp',[],@(x) isempty(x)|isstruct(x));

parse(p,trans_obj,reg_obj,varargin{:});


switch class(reg_obj)
    case 'region_cl'
        
        pings=trans_obj.get_transceiver_pings(reg_obj.Idx_pings);
        
        switch p.Results.mode
            case 'max_reg'
                field='sp';
                if ismember('spdenoised',trans_obj.Data.Fieldname)
                    field='spdenoised';
                end
                
                [Sp_red,idx_r,~,bad_data_mask,bad_trans_vec,~,below_bot_mask,mask_from_st]=trans_obj.get_data_from_region(reg_obj,...
                    'field',field);
                
                Sp_red(bad_data_mask|below_bot_mask|mask_from_st)=nan;
                Sp_red(:,bad_trans_vec)=nan;
                
                [Sp_max,idx_peak_red]=nanmax(Sp_red,[],1);
                idx_peak=idx_r(idx_peak_red);
                pings(isnan(Sp_max))=[];
                idx_peak(isnan(Sp_max))=[];
                %       idx_peak_red(isnan(Sp_max))=[];
                range_tr=trans_obj.get_transceiver_range(idx_peak);   
                range_tr=range_tr';
            otherwise
                range_tr=trans_obj.get_transceiver_range(reg_obj.Idx_r);
                [~,~,~,~,bad_trans_vec,~,~,~]=trans_obj.get_data_from_region(reg_obj,...
                    'field','sp');
                pings(bad_trans_vec)=[];  
                range_tr=repmat(range_tr,1,numel(pings));    
        end
        
        
    case 'struct'
        if ~isfield(reg_obj,'Range')
            range_tr=reg_obj.Target_range_disp;
            pings=reg_obj.Ping_number;
        end
end
f_nom=(trans_obj.Config.Frequency);


if isempty(pings)
   TS_f=[];
   f_vec=[];
   pings=[];
   r_tot=[];
   return;
end

if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(pings), 'Value',0);
    p.Results.load_bar_comp.progress_bar.setText(sprintf('Processing TS(f) estimation at %.0fkHz',f_nom/1e3));
end
[~,~,f_vec,r_tot,~]=trans_obj.processTS_f_v2(p.Results.envdata,pings(1),range_tr(:,1),p.Results.cal,p.Results.att_model);

TS_f=nan(length(pings),length(r_tot),length(f_vec));

[idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');

if alg_found
    varin=trans_obj.Algo(idx_alg).input_params_to_struct();
    max_beam_comp=varin.MaxBeamComp;
    %ts_thr=varin.TS_threshold;
else
    max_beam_comp=12;
    %ts_thr=-200;
end


for ip=1:length(pings)
    
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar ,'Value',ip);
    end
    [Sp_f,compensation_f,f_vec,r_tot,~]=trans_obj.processTS_f_v2(p.Results.envdata,pings(ip),range_tr(:,ip),p.Results.cal,p.Results.att_model);
    
    compensation_f(compensation_f>max_beam_comp)=nan;
    ts_tmp=Sp_f+compensation_f;
    %ts_tmp(ts_tmp<ts_thr)=nan;
    
    TS_f(ip,:,:)=ts_tmp;
end
% 
% if strcmpi(trans_obj.Mode,'FM')
%     [f_min_3dB,f_max_3dB]=trans_obj.get_3dB_f();
%     
%     idx_f_keep=f_vec>=f_min_3dB&f_vec<=f_max_3dB;
%     
%     TS_f(:,:,~idx_f_keep)=nan;
%     TS_f(:,:,~idx_f_keep')=nan;
%     
% end


end