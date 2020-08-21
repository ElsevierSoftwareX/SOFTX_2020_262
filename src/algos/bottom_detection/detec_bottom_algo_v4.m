%% detec_bottom_algo_v4.m
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
% * 2018-08-07: fully commented (Alex Schimel)
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
function output_struct=detec_bottom_algo_v4(trans_obj,varargin)

%% Input parser
%profile on;
% initialize
p = inputParser;

% defaults and checking functions
default_idx_r_min = 0;
default_idx_r_max = Inf;
default_thr_bottom = -35;
check_thr_bottom = @(x)(x>=-120&&x<=-3);
default_thr_backstep = -1;
check_thr_backstep = @(x)(x>=-12&&x<=12);
check_shift_bot = @(x) isnumeric(x);
check_thr_cum = @(x)(x>=0&&x<=100);

% adding to parser
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'r_min',default_idx_r_min,@isnumeric);
addParameter(p,'r_max',default_idx_r_max,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'thr_bottom',default_thr_bottom,check_thr_bottom);
addParameter(p,'thr_backstep',default_thr_backstep,check_thr_backstep);
addParameter(p,'thr_echo',-35,check_thr_bottom);
addParameter(p,'thr_cum',1,check_thr_cum);
addParameter(p,'shift_bot',0,check_shift_bot);
addParameter(p,'rm_rd',0);
addParameter(p,'interp_method','none');
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',0,@(x) x>=0);

% and parse
parse(p,trans_obj,varargin{:});

output_struct.done =  false;

if p.Results.block_len==0
    block_len=get_block_len(10,'cpu');
else
    block_len=p.Results.block_len;
end

% Set range and pings to entire file or region extent
if isempty(p.Results.reg_obj)
    idx_r = 1:length(trans_obj.get_transceiver_range());
    idx_ping_tot = 1:length(trans_obj.get_transceiver_pings());
else
    idx_r = p.Results.reg_obj.Idx_r;
    idx_ping_tot = p.Results.reg_obj.Idx_ping;
end

% pulse length
[~,Np] = trans_obj.get_pulse_Teff(1);
[~,Np_p] = trans_obj.get_pulse_length(1);

% remove from calculation samples to close to start of record
idx_r(idx_r<2*nanmax(Np_p)) = [];


% get range corresponding to samples
range_tot = trans_obj.get_transceiver_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

% bail with those empty results if not enough samples
if isempty(idx_r)
    disp_perso([],'Nothing to detect bottom from...');
    output_struct.bottom=[];
    output_struct.bs_bottom=[];
    output_struct.idx_bottom=[];
    output_struct.idx_ringdown=[];
    output_struct.idx_ping=[];
    return;
end

range_tot = trans_obj.get_transceiver_range(idx_r);

% inititialize results
bot_idx_tot = nan(1,numel(idx_ping_tot));
BS_bottom_tot = nan(1,numel(idx_ping_tot));
idx_ringdown_tot = nan(1,numel(idx_ping_tot));

% processing is done in block. Calculate block size and number of
% iterations
block_size = nanmin(ceil(block_len/numel(idx_r)),numel(idx_ping_tot));
num_ite = ceil(numel(idx_ping_tot)/block_size);

% udpate prgoress bar
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end



switch trans_obj.Mode
    case 'CW'
        win_size = 2*Np+1;
    otherwise
        win_size = Np;
end

win_size=nanmax(win_size,5);

% block processing loop
for ui = 1:num_ite
    
    % pings for this block
    idx_ping = idx_ping_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_ping_tot)));
    
    % mask data outside of region if processing for region/selection
    if isempty(p.Results.reg_obj)
        mask = ones(numel(idx_r),numel(idx_ping));
    else
        mask = p.Results.reg_obj.get_sub_mask(idx_r-p.Results.reg_obj.Idx_r(1)+1,idx_ping-p.Results.reg_obj.Idx_ping(1)+1);
    end
    
    % get data to be used for this block (normal or denoised TS uncompensated)
    if p.Results.denoised > 0
        Sp = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','spdenoised');
        if isempty(Sp)
            Sp = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sp');
        end
    else
        Sp = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sp');
    end
    
    % If no TS unc, take Sv
    if isempty(Sp)
        Sp = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sv');
    end
    
    % mask outside of region
    Sp(mask==0) = -999;
    
    % mask the spikes too
    spikes =trans_obj.get_spikes(idx_r,idx_ping);
    
    if ~isempty(spikes)
        Sp(spikes>0) = -999;
    end
    
    % get parameters
    thr_bottom =  p.Results.thr_bottom;
    thr_backstep = p.Results.thr_backstep;
    r_min = nanmax(p.Results.r_min,2);
    r_max = p.Results.r_max;
    thr_echo = p.Results.thr_echo;
    thr_cum  = p.Results.thr_cum/100; % thr_cum in percentage
    
    % get size of data
    [nb_samples,nb_pings] = size(Sp);
    
    % edit maximum range
    if r_max == Inf
        idx_r_max = nb_samples;
    else
        [~,idx_r_max] = nanmin(abs(r_max-range_tot));
        idx_r_max = nanmin(idx_r_max,nb_samples);
        idx_r_max = nanmax(idx_r_max,10);
    end
    
    % edit minimum range
    [~,idx_r_min] = nanmin(abs(r_min-range_tot));
    idx_r_min = nanmax(idx_r_min,2*Np_p-idx_r(1));
    idx_r_min = nanmin(idx_r_min,nb_samples);
    
    % remove data out of min and max range
    Sp(1:idx_r_min,:) = nan;
    Sp(idx_r_max:end,:) = nan;
    
    % Turn TS into surface backscatter
    BS = bsxfun(@minus,Sp,10*log10(range_tot));
    BS(isnan(BS)) = -999;
    
    % record as original before mods
    BS_ori = BS;
    
    
    % ringdown analysis
    if strcmpi(trans_obj.Mode,'FM')
        idx_ringdown = ones(1,numel(idx_ping));
    else
        if p.Results.rm_rd
            % define ringdown
            ringdown = trans_obj.Data.get_subdatamat('idx_r',ceil(Np/3),'idx_ping',idx_ping,'field','power');
            if isempty(ringdown)
                ringdown = trans_obj.Data.get_subdatamat('idx_r',ceil(Np/3),'idx_ping',idx_ping,'field','sv');
            end
            RingDown = pow2db_perso(ringdown);
            idx_ringdown = analyse_ringdown(RingDown,0.1);
        else
            idx_ringdown = ones(1,numel(idx_ping));
        end
    end
    
    % remove ringdown
    BS(:,~idx_ringdown) = nan;
    
    % max BS in ping
    [max_bs,~] = nanmax(BS);
    
    % keep only samples whose BS is greater than the max minus thr_echo
    Bottom_region_temp = bsxfun(@gt,BS,max_bs+thr_echo);
    
    % remove pings where no sample has BS exceeding BS_thr:
    Bottom_region_temp(:,max_bs<thr_bottom) = 0;
    

    
    % filter result to remove isolated bits and fill holes
    Bottom_region_temp = ceil(filter2_perso(ones(win_size,5),Bottom_region_temp))>=0.7;
    
    % I don't understand this bit. It seems we remove the pings in the mask
    % that have no bottom candidate, and then we re-create one at the
    % original size which has zeros where the original had no bottom
    % candidate... Suggesting replacing it with Bottom_region =
    % double(Bottom_region_Ttemp); or better, just call Bottom_Region_temp
    % Bottom_region from the beggining. - Alex
    idx_empty = nansum(Bottom_region_temp)==0;
    Bottom_region_temp(:,idx_empty) = [];
    Bottom_region = zeros(size(BS));
    Bottom_region(:,~idx_empty) = Bottom_region_temp;
    
    % turn this mask into sample numbers
    idx_bottom = bsxfun(@times,Bottom_region,(1:nb_samples)');
    idx_bottom(~Bottom_region) = nan;
    idx_bottom(end,(nansum(idx_bottom)==0)) = nb_samples;
    
    % topmost in this mask to be used as bottom temporarily
    bot_idx_tmp = nanmin(idx_bottom);
    
    % turn this into linear indexing
    [I_bottom,J_bottom] = find(~isnan(idx_bottom));
    
    I_bottom(I_bottom>nb_samples) = nb_samples;
    
    % add to the list the samples at twice the distance, aka first multiple
    % of the bottom detect
    J_double_bottom = [J_bottom ; J_bottom ; J_bottom];
    I_double_bottom = [I_bottom ; 2*I_bottom ; 2*I_bottom+1];
    I_double_bottom(I_double_bottom > nb_samples) = nan;
    
    % Index of places containing the double bottom echo
    idx_double_bottom = I_double_bottom(~isnan(I_double_bottom)) + nb_samples*(J_double_bottom(~isnan(I_double_bottom))-1);
    Double_bottom = nan(nb_samples,nb_pings);
    Double_bottom(idx_double_bottom) = 1;
    Double_bottom_region = ~isnan(Double_bottom);
    
    % turn BS to linear
    BS_lin = 10.^(BS/10);
    
    %%% Alex revamping...
    % apply mask and square:
    BS_lin_masked_squared = Bottom_region.*BS_lin.^2;
    
    % normalized cumulative sum of this
    BS_lin_cumsum = bsxfun(@rdivide,cumsum(BS_lin_masked_squared,1),nansum(BS_lin_masked_squared));
    
    %%% end of revamping. Old code below
    % BS_lin_norm = bsxfun(@rdivide,BS_lin_masked_squared,nansum(BS_lin_masked_squared));
    % BS_lin_norm(isnan(BS_lin_norm)) = 0;
    % BS_lin_cumsum = bsxfun(@rdivide,cumsum(BS_lin_norm,1),sum(BS_lin_norm));
    
    % apply cumsum threshold:
    BS_lin_cumsum(BS_lin_cumsum<thr_cum) = inf;
    [~,bot_idx] = min(BS_lin_cumsum);
    % old code - dont need to remove thr_cum if all below thr was set to inf
    % [~,Bottom] = min((abs(BS_lin_cumsum-thr_cum)));
    
    % Bottom will be the lowest sample between this and the temp defined
    % earlier
    bot_idx = nanmax(bot_idx_tmp,bot_idx);
    
    % 3. backstepping
    
    % backstep size is one pulse length, unless smaller than 2 sample
    backstep = nanmax([4 Np]);
    
    for iip = 1:nb_pings
        
        % taking BS before ringdown was removed
        BS_ping = BS_ori(:,iip);
%         f=figure();ax=axes(f,'nextplot','add');plot(ax,BS_ping);
%         vline=xline(ax,bot_idx(iip),'r');
%         ylim(ax,[-80 -30]);
        % if bottom is not too close to start
        if bot_idx(iip) > 2*backstep
            
            if bot_idx(iip) > backstep
                % find maximum BS in an interval ONE pulse length above bottom
                [bs_val,idx_max_tmp] = nanmax(BS_ping((bot_idx(iip)-backstep):bot_idx(iip)-1));
            else
                % if bottom is too close to start, just exit
                 continue;
            end
            
            % if that BS value is valid and more than the bottom BS plus thr_backstep
            while bs_val >= (BS_ping(bot_idx(iip))+thr_backstep) && bs_val > thr_bottom+thr_echo+thr_backstep
                
                if bot_idx(iip)-(backstep-idx_max_tmp+1) > 0
                    % move the bottom to that value
                    bot_idx(iip) = bot_idx(iip)-(backstep-idx_max_tmp+1);
                end
                %bot_idx(iip)
                %vline.Value=bot_idx(iip);
                if bot_idx(iip) > backstep
                    % calculate next value
                    [bs_val,idx_max_tmp] = nanmax(BS_ping((bot_idx(iip)-backstep):bot_idx(iip)-1));
                else
                    break;
                end
                
            end
        end
        
        bot_idx(iip) = nanmax(bot_idx(iip)-backstep,1);
    end
    
    % cleaning up that bottom
    bot_idx(bot_idx<=idx_r_min) = nan;
    bot_idx(idx_empty) = nan;
    
    % filtered and masked version of BS

    bot_r=nan(size(bot_idx));
    bot_r(~isnan(bot_idx))=range_tot(bot_idx(~isnan(bot_idx)));
    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

    echolength_theory = echo_length(range(Np),1/2*(faBW+psBW),10,bot_r);
    
    win_size=ceil(mode(echolength_theory)/nanmean(diff(range_tot)));
    win_size =  nanmax(win_size,5);
    
    BS_filter = (20*log10(filter2_perso(ones(win_size,1)/(win_size),10.^(BS/20)))).*Bottom_region;
    BS_filter(Bottom_region==0) = nan;
    
    BS_bottom = nanmax(BS_filter);
    BS_bottom(isnan(bot_idx)) = nan;
    
    % pings for which the max BS per ping (after filtering BS) is lower
    % than thr_bottom.. Those should have been removed at first.
    idx_low = (BS_bottom<thr_bottom);
    if p.Results.denoised > 0
        bot_idx = bot_idx - 1;
    end
    % shift the bottom up
    bot_idx = bot_idx - ceil(p.Results.shift_bot./nanmax(diff(range_tot)));
    
    % nan the bottom for those low bottom BS pings
    bot_idx(idx_low) = nan;
    BS_bottom(idx_low) = nan;
    
    bot_idx(bot_idx<=0) = 1;
    
    % save those results for this iteration
    idx_ping = idx_ping-idx_ping_tot(1)+1;
    bot_idx_tot(idx_ping)                 = bot_idx;
    BS_bottom_tot(idx_ping)              = BS_bottom;
    idx_ringdown_tot(idx_ping)           = idx_ringdown;
    
    % update progress bar
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
    
end

% update bottom with range offset
bot_idx_tot = bot_idx_tot + idx_r(1) - 1;

switch lower(p.Results.interp_method)
    case 'none'
        
    otherwise
        if nansum(~isnan(bot_idx_tot))>=2
            F=griddedInterpolant(idx_ping_tot(~isnan(bot_idx_tot)),bot_idx_tot(~isnan(bot_idx_tot)),lower(p.Results.interp_method),'none');
            bot_idx_tot=F(idx_ping_tot);
            bot_idx_tot=ceil(bot_idx_tot);
        end
end

output_struct.bottom = bot_idx_tot;
output_struct.bs_bottom    = BS_bottom_tot;
output_struct.idx_ringdown = idx_ringdown_tot;
output_struct.idx_ping    = idx_ping_tot;

old_tag = trans_obj.Bottom.Tag;
old_bot = trans_obj.Bottom.Sample_idx;

old_bot(output_struct.idx_ping) = output_struct.bottom;

new_bot = bottom_cl('Origin','Algo_v3',...
    'Sample_idx',old_bot,...
    'Tag',old_tag);

trans_obj.Bottom = new_bot;
output_struct.done =  true;
% profile off;
% profile viewer;

