%% detec_bottom_algo_v3.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% TODO
%
% *OUTPUT VARIABLES*
%
% TODO
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output_struct=detec_bottom_algo_v3(trans_obj,varargin)

%profile on;
%Parse Arguments

p = inputParser;

default_idx_r_min=0;

default_idx_r_max=Inf;

default_thr_bottom=-35;
check_thr_bottom=@(x)(x>=-120&&x<=-3);

default_thr_backstep=-1;
check_thr_backstep=@(x)(x>=-12&&x<=12);

check_shift_bot=@(x) isnumeric(x);
check_filt=@(x)(x>=0)||isempty(x);

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'r_min',default_idx_r_min,@isnumeric);
addParameter(p,'r_max',default_idx_r_max,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'thr_bottom',default_thr_bottom,check_thr_bottom);
addParameter(p,'thr_backstep',default_thr_backstep,check_thr_backstep);
addParameter(p,'v_filt',10,check_filt);
addParameter(p,'h_filt',10,check_filt);
addParameter(p,'shift_bot',0,check_shift_bot);
addParameter(p,'rm_rd',0);
addParameter(p,'interp_method','none');
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0);
parse(p,trans_obj,varargin{:});

output_struct.done =  false;

if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_transceiver_range());
    idx_pings_tot=1:length(trans_obj.get_transceiver_pings());
else
    idx_pings_tot=p.Results.reg_obj.Idx_pings;
    idx_r=p.Results.reg_obj.Idx_r;
end

[~,Np]=trans_obj.get_pulse_Teff(1);
[~,Np_p]=trans_obj.get_pulse_length(1);

idx_r(idx_r<2*nanmax(Np_p))=[];
%[bot_idx_tot,Double_bottom_region_tot,BS_bottom_tot,idx_bottom_tot,idx_ringdown_tot,idx_pings_tot]


range_tot = trans_obj.get_transceiver_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r)
    disp_perso([],'Nothing to detect bottom from...');
    output_struct.bottom=[];
    output_struct.bs_bottom=[];
    output_struct.idx_ringdown=[];
    output_struct.idx_pings=[];
    return;
end

bot_idx_tot=nan(1,numel(idx_pings_tot));
BS_bottom_tot=nan(1,numel(idx_pings_tot));
idx_ringdown_tot=nan(1,numel(idx_pings_tot));

if isempty(p.Results.block_len)
    block_len = get_block_len(50,'cpu');
else
    block_len= p.Results.block_len;
end

block_size=nanmin(ceil(block_len/numel(idx_r)),numel(idx_pings_tot));
num_ite=ceil(numel(idx_pings_tot)/block_size);


range_tot= trans_obj.get_transceiver_range(idx_r);
dr=nanmean(diff(range_tot));

thr_bottom=p.Results.thr_bottom;
thr_backstep=p.Results.thr_backstep;
r_min=nanmax(p.Results.r_min,2);
r_max=p.Results.r_max;

thr_echo=-35;
thr_cum=1;
load_bar_comp=p.Results.load_bar_comp;

if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end


for ui=1:num_ite
    idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
    


    
    if  isempty(p.Results.reg_obj)
        mask=ones(numel(idx_r),numel(idx_pings));
    else
        mask=p.Results.reg_obj.get_sub_mask(idx_r-p.Results.reg_obj.Idx_r(1)+1,idx_pings-p.Results.reg_obj.Idx_pings(1)+1);
    end
    
    if p.Results.denoised>0
        Sp=trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','spdenoised');
        if isempty(Sp)
            Sp=trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','sp');
        end
    else
        Sp=trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field','sp');
    end
    
    Sp(mask==0)=-999;
    
    [nb_samples,nb_pings]=size(Sp);
       
    
    if r_max==Inf
        idx_r_max=nb_samples;
    else
        [~,idx_r_max]=nanmin(abs(r_max+p.Results.v_filt-range_tot));
        idx_r_max=nanmin(idx_r_max,nb_samples);
        idx_r_max=nanmax(idx_r_max,10);
    end
    
    [~,idx_r_min]=nanmin(abs(r_min-p.Results.v_filt-range_tot));
    idx_r_min=nanmax(idx_r_min,10);
    idx_r_min=nanmin(idx_r_min,nb_samples);
    
    ringdown=trans_obj.Data.get_subdatamat(ceil(Np/3),idx_pings,'field','power');
    RingDown=pow2db_perso(ringdown);
    
    Sp(1:idx_r_min,:)=nan;
    Sp(idx_r_max:end,:)=nan;
    
    %First let's find the bottom...

    heigh_b_filter=floor(p.Results.v_filt/dr)+1;

    b_filter=ceil(nanmin(10,nb_pings/10));

    if p.Results.rm_rd
        idx_ringdown=analyse_ringdown(RingDown,0.05);
    else
        idx_ringdown=ones(size(RingDown));
    end
    
    BS=bsxfun(@minus,Sp,10*log10(range_tot));
    
    BS(isnan(BS))=-999;
    BS_ori=BS;
    
    
    BS(:,~idx_ringdown)=nan;
    BS_lin=10.^(BS/10);
    BS_lin(isnan(BS_lin))=0;
    
    BS_lin_red=BS_lin(idx_r_min:idx_r_max,:);
    
    
    filter_fun = @(block_struct) max(block_struct.data(:));
    BS_filtered_bot_lin=blockproc(BS_lin_red,[heigh_b_filter b_filter],filter_fun);
    [nb_samples_red,~]=size(BS_filtered_bot_lin);
    
    BS_filtered_bot=10*log10(BS_filtered_bot_lin);
    BS_filtered_bot_lin(isnan(BS_filtered_bot_lin))=0;
    
    cumsum_BS=cumsum((BS_filtered_bot_lin),1);
    cumsum_BS(cumsum_BS<=eps)=nan;
    
    if size(cumsum_BS,1)>1
        diff_cum_BS=diff(10*log10(cumsum_BS),1,1);
    else
        diff_cum_BS=zeros(size(cumsum_BS));
    end
    diff_cum_BS(isnan(diff_cum_BS))=0;
    
    [~,idx_max_diff_cum_BS]=nanmax(diff_cum_BS,[],1);
    
    idx_start=idx_max_diff_cum_BS-1;
    idx_end=idx_max_diff_cum_BS+3;
    
    Bottom_region=(bsxfun(@ge,(1:nb_samples_red)',idx_start)&bsxfun(@le,(1:nb_samples_red)',idx_end));
    max_bs=nanmax(BS_filtered_bot);
    Max_BS_reg=(bsxfun(@gt,BS_filtered_bot,max_bs+thr_echo));
    Max_BS_reg(:,max_bs<thr_bottom)=0;
    
    Bottom_region=find_cluster((Bottom_region>0&BS_filtered_bot>=thr_bottom&Max_BS_reg),1);
    
    Bottom_region=ceil(filter(ones(1,3)/3,1,Bottom_region));
    Bottom_region_red=imresize(Bottom_region,size(BS_lin_red),'nearest');
    Bottom_region=zeros(size(BS_lin));
    Bottom_region(idx_r_min:idx_r_max,:)=Bottom_region_red;
    
    n_permut=nanmin(floor((heigh_b_filter+1)/4),nb_samples);
    Permut=[nb_samples-n_permut+1:nb_samples 1:nb_samples-n_permut];
    
    Bottom_region=Bottom_region(Permut,:);
    Bottom_region(1:n_permut,:)=0;
    
    idx_bottom=bsxfun(@times,Bottom_region,(1:nb_samples)');
    idx_bottom(~Bottom_region)=nan;
    idx_bottom(end,(nansum(idx_bottom)==0))=nb_samples;
    
    
    [I_bottom,J_bottom]=find(~isnan(idx_bottom));
    
    I_bottom(I_bottom>nb_samples)=nb_samples;
    
    J_double_bottom=[J_bottom ; J_bottom ; J_bottom];
    I_double_bottom=[I_bottom ; 2*I_bottom ; 2*I_bottom+1];
    I_double_bottom(I_double_bottom > nb_samples)=nan;
    idx_double_bottom=I_double_bottom(~isnan(I_double_bottom))+nb_samples*(J_double_bottom(~isnan(I_double_bottom))-1);
    Double_bottom=nan(nb_samples,nb_pings);
    Double_bottom(idx_double_bottom)=1;
    Double_bottom_region=~isnan(Double_bottom);
    
    %%%%%%%%%%%%%%%%%%%%%Bottom detection and BS analysis%%%%%%%%%%%%%%%%%%%%%%
    
    
    BS_lin_norm=bsxfun(@rdivide,Bottom_region.*BS_lin,nansum(Bottom_region.*BS_lin));
    
    
    BS_lin_norm_bis=BS_lin_norm;
    BS_lin_norm_bis(isnan(BS_lin_norm))=0;
    BS_lin_cumsum=(cumsum(BS_lin_norm_bis,1)./repmat(sum(BS_lin_norm_bis),size(Bottom_region,1),1));
    BS_lin_cumsum(BS_lin_cumsum<thr_cum/100)=Inf;
    [~,Bottom_temp]=min((abs(BS_lin_cumsum-thr_cum/100)));
    Bottom_temp_2=nanmin(idx_bottom);
    Bottom=nanmax(Bottom_temp,Bottom_temp_2);
    
    backstep=nanmax([1 Np]);
    
    for iuu=1:nb_pings
        
        BS_ping=BS_ori(:,iuu);
        if Bottom(iuu)>2*backstep
            Bottom(iuu)=Bottom(iuu)-backstep;
            if Bottom(iuu)>backstep
                [bs_val,idx_max_tmp]=nanmax(BS_ping((Bottom(iuu)-backstep):Bottom(iuu)-1));
            else
                continue;
            end
            
            while bs_val>=BS_ping(Bottom(iuu))+thr_backstep &&bs_val>-999
                if Bottom(iuu)-(backstep-idx_max_tmp+1)>0
                    Bottom(iuu)=Bottom(iuu)-(backstep-idx_max_tmp+1);
                end
                if Bottom(iuu)>backstep
                    [bs_val,idx_max_tmp]=nanmax(BS_ping((Bottom(iuu)-backstep):Bottom(iuu)-1));
                else
                    break;
                end
            end
        end
    end
    
    % figure();plot(Bottom_temp)
    % hold on;plot(Bottom_temp_2)
    % plot(Bottom);
    
    Bottom(Bottom==1)=nan;
    Bottom(nanmin(idx_bottom)>=nanmax(1,nb_samples-round(heigh_b_filter)/2))=nan;
    
    BS_filter=(20*log10(filter(ones(4*Np,1)/(4*Np),1,10.^(BS/20)))).*Bottom_region;
    BS_filter(Bottom_region==0)=nan;
    
    BS_bottom=nanmax(BS_filter);
    BS_bottom(isnan(Bottom))=nan;
    
    Bottom=Bottom- ceil(p.Results.shift_bot./nanmax(diff(range_tot)));
    Bottom(Bottom<=0)=1;
    
    idx_pings=idx_pings-idx_pings_tot(1)+1;
    % profile off;
    % profile viewer;
    bot_idx_tot(idx_pings)=Bottom;
    BS_bottom_tot(idx_pings)=BS_bottom;
    idx_ringdown_tot(idx_pings)=idx_ringdown;
    
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
end


bot_idx_tot=bot_idx_tot+idx_r(1)-1;

switch lower(p.Results.interp_method)
    case 'none'
        
    otherwise
        if nansum(~isnan(bot_idx_tot))>=2
            F=griddedInterpolant(idx_pings_tot(~isnan(bot_idx_tot)),bot_idx_tot(~isnan(bot_idx_tot)),lower(p.Results.interp_method),'none');
            bot_idx_tot=F(idx_pings_tot);
            bot_idx_tot=ceil(bot_idx_tot);
        end
end

output_struct.bottom=bot_idx_tot;
output_struct.bs_bottom=BS_bottom_tot;
output_struct.idx_ringdown=idx_ringdown_tot;
output_struct.idx_pings=idx_pings_tot;


old_tag = trans_obj.Bottom.Tag;
old_bot = trans_obj.Bottom.Sample_idx;
old_bot(output_struct.idx_pings) = output_struct.bottom;

new_bot = bottom_cl('Origin','Algo_v3',...
    'Sample_idx',old_bot,...
    'Tag',old_tag);
trans_obj.Bottom = new_bot;

% profile off;
% profile viewer;
output_struct.done =  true;
end


