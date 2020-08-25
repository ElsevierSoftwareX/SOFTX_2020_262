%% bad_pings_removal_3.m
%
% Bad transmits detection algorithm
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |trans_obj|: TODO: write description and info on variable
% * |denoised|: TODO description (Optional. Num or logical. Default: 0).
% * |BS_std|: TODO description (Optional).
% * |Ringdown_std|: TODO: write description and info on variable
% * |Ringdown_std_bool|: TODO: write description and info on variable
% * |BS_std_bool|: TODO description (Optional. Num or logical. Default:|true|).
% * |thr_spikes_Above|: TODO description (Optional).
% * |thr_spikes_Below|: TODO description (Optional).
% * |Above|: TODO description (Optional. Num or logical. Default:|true|).
% * |Below|: TODO description (Optional. Num or logical. Default:|true|).
% * |reg_obj|: TODO: write description and info on variable
% * |load_bar_comp|: TODO description (Optional. Default: empty);
% * |block_len|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |idx_noise_sector_tot|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
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
function output_struct = bad_pings_removal_3(trans_obj,varargin)

global DEBUG


%% INPUT VARIABLES MANAGEMENT

p = inputParser;

% default values for input parameters
default_Ringdown_std = 0.05;
default_BS_std       = 9;
default_spikes       = 3;


% functions for valid values
check_BS_std = @(x)(x>=0)&&(x<=50);
check_spikes = @(x)(x>=0&&x<=100);

% fill in the parser
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'BS_std',default_BS_std,check_BS_std);
addParameter(p,'Ringdown_std_bool',true,@(x) islogical(x)||isnumeric(x));
addParameter(p,'Ringdown_std',default_Ringdown_std,check_BS_std);
addParameter(p,'BS_std_bool',true,@(x) islogical(x)||isnumeric(x));
addParameter(p,'thr_spikes_Above',default_spikes,check_spikes);
addParameter(p,'thr_spikes_Below',default_spikes,check_spikes);
addParameter(p,'Above',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'Below',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'Additive',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'thr_add_noise',-140,@(x)(x>=-inf&&x<=0));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);

% parse
parse(p,trans_obj,varargin{:});

% grab values from the parser
BS_std           = p.Results.BS_std;
BS_std_bool      = p.Results.BS_std_bool;
thr_spikes_Above = p.Results.thr_spikes_Above;
thr_spikes_Below = p.Results.thr_spikes_Below;
Above            = p.Results.Above;
Below            = p.Results.Below;


%%
if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Automatic detection of bad pings...');
end
output_struct.done =  false;

%% PRE-PROCESSING

% indices of all samples and pings
if isempty(p.Results.reg_obj)
    idx_r = 1:length(trans_obj.get_transceiver_range());
    idx_ping_tot = 1:length(trans_obj.get_transceiver_pings());
else
    idx_ping_tot = p.Results.reg_obj.Idx_ping;
    idx_r = p.Results.reg_obj.Idx_r;
end

% total number of pings
nb_pings_tot = numel(idx_ping_tot);

% initialize output (index of bad pings)
idx_noise_sector_tot = [];

% If doing block processing, calculate number of iterations needed
block_size = nanmin(ceil(p.Results.block_len/numel(idx_r)),numel(idx_ping_tot));
num_ite = ceil(numel(idx_ping_tot)/block_size);

% initialize progress bar
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end


cal=trans_obj.get_cal();
c=trans_obj.get_soundspeed(idx_r);
f_nom = trans_obj.Config.Frequency;
f_c=trans_obj.get_center_frequency();
G=cal.G0+10*log10(f_nom./f_c);

% BLOCK PROCESSING
for ui = 1:num_ite
    
    % ping indices for this block
    idx_ping = idx_ping_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_ping_tot)));
    
    
    %% GRABBING AND PREPARING DATA
    
    % grab data to work on: normal or denoised
    if p.Results.denoised > 0
        % get denoised Sv
        Sv = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','svdenoised');
        % failsafe: if no denoised data, grab normal Sv
        if isempty(Sv)
            Sv = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sv');
            warning('denoised Sv not available for bad pings detection. Using normal Sv instead.');
        end
    else
        Sv = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sv');
    end
     
    % get data size
    [nb_samples,nb_pings] = size(Sv);
    
    % if applying the algo on a region, define the region mask...
    if isempty(p.Results.reg_obj)
        mask = zeros(numel(idx_r),numel(idx_ping));
    else
        mask = ~p.Results.reg_obj.get_sub_mask(idx_r-p.Results.reg_obj.Idx_r(1)+1,idx_ping-p.Results.reg_obj.Idx_ping(1)+1);
    end
    
    % ... and apply mask to the data
    
    Sv(mask==1) = -999;
    
    % nb of samples in pulse length
    [~,Np] = trans_obj.get_pulse_length(1);

    % remove the ringdown (twice the pulse length for now)
    
    if idx_r(1) <= 2*Np
        start_sample = nanmin([2*Np-idx_r(1)+1 nb_samples]);
        Sv(1:start_sample,:) = nan;  
    else
        start_sample = 1;
    end
    

    %% PROCESSING #1: RINGDOWN ANALYSIS
    
    % grab inside the ringdown (original data "power") the ONE characteristic sample
    ringdown = trans_obj.Data.get_subdatamat('idx_r',ceil(Np/3),'idx_ping',idx_ping,'field','power');
    RingDown = pow2db_perso(ringdown);
    
    % and analyze it if it this was asked in input, using the parameter provided
    if p.Results.Ringdown_std_bool
        idx_ringdown = analyse_ringdown(RingDown,p.Results.Ringdown_std);
    else
        idx_ringdown = ones(size(RingDown));
    end
    
    % save flagged indices
    idx_rd = find(~idx_ringdown);
    
    
    %% PROCESSING #2: UNDEFINED BOTTOM LINE
    
    % get the bottom line sample in each ping
    idx_bottom = trans_obj.get_bottom_idx(idx_ping);
    
    % maximum size for a block of pings with undefined bottom to be flagged
    maxBlockSize = 5;
    if maxBlockSize > length(idx_bottom)
        maxBlockSize = length(idx_bottom);
    end
    
    % pad idx_bottom so algorithm can deal with pings at the edges
    idx_bottom = [99 idx_bottom 99];
    
    % find indices of start of blocks too big
    win = [zeros(1,maxBlockSize) ones(1,maxBlockSize+1)];
    temp = conv(isnan(idx_bottom),fliplr(win),'same');
    idx_start = find( temp(1:end-1)~=maxBlockSize+1 & temp(2:end)==maxBlockSize+1)+1;
    
    % find indices of end of blocks too big
    temp = conv(isnan(idx_bottom),win,'same');
    idx_end = find( temp(1:end-1)==maxBlockSize+1 & temp(2:end)~=maxBlockSize+1);
    
    % all indices of blocks to ignore
    idx_block = [];
    
    for ii = 1:length(idx_start)
        idx_block = [idx_block,idx_start(ii):idx_end(ii)];
    end
    
    % all nans minus those in blocks
    idx_bottom_nan = setdiff( find(isnan(idx_bottom)),idx_block);
    
    % idx_bottom back to normal and offset indices
    idx_bottom = idx_bottom(2:end-1);
    idx_bottom_nan = idx_bottom_nan(2:end-1)-1;
    
    % clear some space
    clear win temp idx_start idx_end idx_block
    
    
    
    %% PROCESSING #3: BOTTOM ECHO BACKSCATTER
    
    if BS_std_bool > 0
        
        % compute pseudo-BS as Sv + 10 log(R)
        Range = trans_obj.get_transceiver_range(idx_r);
        BS = bsxfun(@plus,Sv,10*log10(Range));
        
        % calculate the mean BS of the bottom echo
        idx_bs = bsxfun(@(x,y) (x>=y) & (x<=y*11/10), trans_obj.get_transceiver_samples(idx_r), idx_bottom);
        BS(~idx_bs) = nan;
        BS_bottom = lin_space_mean(BS);
        
        % nan that value if bottom is outside of data bounds (in case of
        % regions) and if defined bottom line is last sample in ping
        BS_bottom(idx_bottom<start_sample) = nan;
        Range_t = trans_obj.get_transceiver_range();
        BS_bottom(idx_bottom==numel(Range_t)) = nan;
        
        % also nan than value if there is no bottom detected
        BS_bottom_analysis = BS_bottom;
        BS_bottom_analysis(isnan(idx_bottom)|idx_bottom==nb_samples) = nan;
        
        % BS_std_up = -20*log10((sqrt(4/pi-1)));
        % BS_std_dw = 20*log10((sqrt(4/pi-1)));
        
        % preparing threshold parameters
        BS_std_up = BS_std;
        BS_std_dw = -BS_std;
        
        % We're going to run two average filters through the bottom echo,
        % at two different lenghts:
        b_filter = 3:2:5;
        
        % save original
        BS_bottom_analysis_original = BS_bottom_analysis;
        
        if DEBUG
            figure();
            
            subplot(211)
            plot(BS_bottom_analysis_original,'k');
            hold on
            grid on
            title('mean bottom echo BS')
            xlabel('ping #')
            ylabel('BS (dB)')
            
            subplot(212)
            plot(BS_std_up*ones(1,nb_pings),'k')
            hold on
            plot(BS_std_dw*ones(1,nb_pings),'k')
            grid on
            title('mean bottom echo BS minus moving average')
            xlabel('ping #')
            ylabel('BS (dB)')
        end
        
        % apply each filter and save results
        for j = 1:length(b_filter)
            
            % create filter
            filter_window = ones(1,b_filter(j));
            
            % apply the average filter to linear data
            % but why the denominator? It's all ones.. ???
            % Mean_BS(j,:) = 20*log10( filter_nan(filter_window,10.^(BS_bottom_analysis/20)) ./ filter_nan(filter_window,ones(1,length(BS_bottom))) );
            Mean_BS = 20*log10( filter_nan(filter_window,10.^(BS_bottom_analysis/20)) );
            
            % find indices where filtered signal do not exceed thresholds
            idx_temp = (BS_bottom_analysis-Mean_BS <= BS_std_up) & (BS_bottom_analysis-Mean_BS >= BS_std_dw);
            
            if DEBUG
                subplot(211)
                plot(Mean_BS)
                plot(find(~idx_temp),BS_bottom_analysis_original(~idx_temp),'rx');
                subplot(212)
                plot(BS_bottom_analysis-Mean_BS)
            end
            
            % nan the bottom BS where signal exceeded threshold before continuing to next filter
            BS_bottom_analysis(~idx_temp) = nan;
            
        end
        
        % create a vector listing where bottom BS was OK, and add those
        % pings where we had no detected bottom
        idx_bottom_bs_eval = ~isnan(BS_bottom_analysis);
        idx_bottom_bs_eval(isnan(idx_bottom)) = 1;
        idx_bottom_bs_eval(isnan(BS_bottom)) = 1;
        
    else
        % not apply bottom BS analysis - keep all pings here
        idx_bottom_bs_eval = ones(1,nb_pings);
        
    end
    
    % save indices of flagged pings
    idx_bad_bs = find(~idx_bottom_bs_eval);
    
    
    
    %% PROCESSING #4: BAD DATA ABOVE AND/OR BELOW BOTTOM
    
    
    % filter the bottom line
    if numel(idx_bottom) > 3
        idx_bottom = ceil( filter_nan(ones(1,3),idx_bottom) ./ filter_nan(ones(1,3),~isnan(idx_bottom)) );
    end
    idx_bottom(isnan(idx_bottom)) = nb_samples;
    
    % find samples that are above and below the filtered bottom detect, but only within hard-coded ranges:
    if isempty(p.Results.reg_obj)
        % if data is NOT a region (aka full dataset)
        
        % old method:
        % idx_above = bsxfun(@(x,y) (x < y*9.5/10) & (x > y/2)     , idx_r(:) , idx_bottom);
        % idx_below = bsxfun(@(x,y) (x > y*12/10)  & (x < y*14/10) , idx_r(:) , idx_bottom);
        
        % new method:
        
        % above data is all data between ringdown and bottom detect
        idx_above = bsxfun(@lt,(1:nb_samples)',idx_bottom);
        idx_above(1:start_sample,:) = false;
        
        % range of first bottom multiple
        [I_bottom,J_bottom] = find(~isnan(idx_bottom));
        I_bottom(I_bottom>nb_samples) = nb_samples;
        J_double_bottom = [J_bottom ; J_bottom ; J_bottom];
        I_double_bottom = [I_bottom ; 2*I_bottom ; 2*I_bottom+1];
        I_double_bottom(I_double_bottom > nb_samples) = nan;
        idx_double_temp = I_double_bottom(~isnan(I_double_bottom))+nb_samples*(J_double_bottom(~isnan(I_double_bottom))-1);
        idx_double_bottom = repmat((1:nb_samples)',1,nb_pings);
        idx_samples = nan(nb_samples,nb_pings);
        idx_samples(idx_double_temp) = 1;
        idx_double_bottom = idx_samples.*idx_double_bottom;
        
        % below data is all data between 110% of bottom detect and first multiple
        idx_below = bsxfun(@gt,(1:nb_samples)',idx_bottom*11/10)&isnan(idx_double_bottom);
        idx_below(1:start_sample,:) = false;
        
    else
        % if data is a region
        idx_above = bsxfun(@(x,y) (x < y)       , idx_r(:) , idx_bottom);
        idx_below = bsxfun(@(x,y) (x > y*11/10) , idx_r(:) , idx_bottom);
    end
    
    % initialize detection of bad pings within those zones
    idx_bad_above = [];
    idx_bad_below = [];
    
    % Analysis of data above bottom
    if Above > 0
        
        % compute average Sv above bottom
        Sv_Above = nan(size(Sv));
        Sv_Above(idx_above) = Sv(idx_above);
        Sv_Above(Sv_Above==-999)=nan;
        % sv_mean_vert_above = lin_space_mean(Sv_Above);
        sv_mean_vert_above = nanmean(Sv_Above);
        
        % apply peak finder algorithm.
        % looking for positive AND negative peaks
        
        % old method:
        % thr_down = -thr_spikes_Above*[1 2 2 2];
        % thr_up   = -thr_spikes_Above*[1 2 2];
        % [idx_bad_up,idx_bad_down] = find_idx_bad_up_down(sv_mean_vert_above,thr_down,thr_up);
        
        % new method using Matlab function
        [~,idx_bad_up] = findpeaks(sv_mean_vert_above,'MaxPeakWidth',3,'Threshold',thr_spikes_Above);
        [~,idx_bad_down] = findpeaks(-sv_mean_vert_above,'MaxPeakWidth',3,'Threshold',thr_spikes_Above);
        
        % combine results
        idx_bad_above = union(idx_bad_up,idx_bad_down);
        
        if DEBUG
            figure;
            plot(sv_mean_vert_above);
            hold on
            grid on
            plot(idx_bad_up,sv_mean_vert_above(idx_bad_up),'kx');
            plot(idx_bad_down,sv_mean_vert_above(idx_bad_down),'rx');
            tmp = sv_mean_vert_above;
            tmp(idx_bad_above) = NaN;
            plot(tmp,'k','Linewidth',2);
            xlabel('ping #')
            ylabel('BS (dB)')
            title('Above bottom analysis')
            clear tmp
        end
        
    else
        
        % not applying spike detection above
        sv_mean_vert_above = nan(1,nb_pings);
        
    end
    
    % Analysis of data below bottom
    if Below > 0
        
        % compute average Sv below bottom
        Sv_Below = nan(size(Sv));
        Sv_Below(idx_below) = Sv(idx_below);
        Sv_Below(Sv_Below==-999)=nan;
        % sv_mean_vert_below = lin_space_mean(Sv_Below);
        sv_mean_vert_below = nanmean(Sv_Below);
        
        
        % new method using Matlab function
        [~,idx_bad_below] = findpeaks(-sv_mean_vert_below,'MaxPeakWidth',3,'Threshold',thr_spikes_Below);
        
        if DEBUG
            figure;
            plot(sv_mean_vert_below);
            hold on
            grid on
            plot(idx_bad_below,sv_mean_vert_below(idx_bad_below),'kx');
            tmp = sv_mean_vert_below;
            tmp(idx_bad_below) = NaN;
            plot(tmp,'k','Linewidth',2);
            xlabel('ping #')
            ylabel('BS (dB)')
            title('Below bottom analysis')
            clear tmp
        end
        
    else
        
        % not applying spike detection below
        sv_mean_vert_below = nan(1,nb_pings);
        
    end
    
    % old debug figure
    if DEBUG && ~isempty(idx_bad_below) && ~isempty(idx_bad_above)
        sv_mean_vert_bad_below = nan(1,nb_pings);
        sv_mean_vert_bad_above = nan(1,nb_pings);
        sv_mean_vert_bad_below(idx_bad_below) = sv_mean_vert_below(idx_bad_below);
        sv_mean_vert_bad_above(idx_bad_above) = sv_mean_vert_above(idx_bad_above);
        h_fig = new_echo_figure([],'Name','Bad Pings test','Tag','temp_badt');
        ax = axes(h_fig,'nextplot','add');
        grid(ax,'on');
        plot(ax,sv_mean_vert_below,'-+');
        plot(ax,sv_mean_vert_bad_below,'or');
        plot(ax,sv_mean_vert_above,'-x');
        plot(ax,sv_mean_vert_bad_above,'ok');
        legend('Below values','Rem. from below','Above values','Rem. from above');
    end
    
 
  
%% Basic filter for additive noise
if p.Results.Additive
       power = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','power');

    ptx = trans_obj.get_params_value('TransmitPower',idx_ping);
    gain = G(idx_ping);
    lambda = c./f_c(idx_ping);
    switch trans_obj.Config.TransceiverName
        case {'FCV30'}
            tmp=10*log10(single(power))-2*gain;
            
        case {'ASL'}
            tmp=10*log10(single(power));
           
        otherwise
            tmp=10*log10(single(power))-2*gain-10*log10(ptx.*lambda.^2/(16*pi^2));
    end
    
    prec=0.1;
    
    tmp(1:start_sample,:) = nan;
    tmp(~(idx_above|idx_below)) = nan;
    tmp(isinf(tmp))=nan;
    
    %power_prc_25=prctile(ceil(tmp/prec)*prec,251);
    power_prc_25=prctile(tmp,25,1);
    if DEBUG
        power_mode=mode(ceil(tmp/prec)*prec);
        
        power_mean=pow2db(nanmean(db2pow(tmp)));
        new_echo_figure();plot(idx_ping,power_mode,'r');hold on;
        plot(idx_ping,power_mean,'k')
        plot(idx_ping,power_prc_25,'b');
        yline(p.Results.thr_add_noise,'b','Noise thr.');
        legend({'Mode','Mean','25-percentile'});
        %     figure();histogram(tmp(:,2),100);hold on;histogram(tmp(:,6),100)
    end
    idx_add=find(power_prc_25>p.Results.thr_add_noise);
    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText(sprintf('Estimated noise level : %.1fdB',prctile(power_prc_25,50)));
    end
    
else
    idx_add=[];
end

%% FFT analysis for broadband noises... Not used as not working as I hoped
%     if idx_r(1) <= 10*Np
%         start_sample_fft = nanmin([10*Np-idx_r(1)+1 nb_samples]);
%     else
%         start_sample_fft = 1;
%     end
%
%         power_fft = fftshift(abs(fft(power,nfft,1)),1);
%
%         f_mean=nansum(power_fft.^2.*f_fft)./nansum(power_fft.^2);
%
%         f_std=sqrt(nansum((power_fft.^2.*(f_fft-f_mean).^2)./nansum(power_fft.^2)));
%         w_bw=range(f_fft)/(sqrt(6));
%         idx_fft=find(f_std>w_bw/4);
% %         figure();
% %         imagesc(1:size(power_fft,2),f_fft/1e3,pow2db_perso(power_fft));hold on;
% %         plot(1:size(power_fft,2),f_mean/1e3);
% %         plot(1:size(power_fft,2),(f_mean-f_std)/1e3,'r');
% %         plot(1:size(power_fft,2),(f_mean+f_std)/1e3,'r');
% %         yline(-w_bw/1e3/4);
% %         yline(w_bw/1e3/4);
    idx_fft=[];


    
    %% COMBINING ALL ALGORITHMS
    
    % combining all flagged pings across all algos
    idx_noise_sector = unique([idx_bad_below(:)' idx_bad_above(:)' idx_bad_bs(:)' idx_rd(:)' idx_bottom_nan(:)' idx_fft(:)' idx_add(:)']);
    idx_noise_sector = idx_noise_sector + idx_ping(1) - 1;
    
    
    
    % add results for this block to the list before moving on the next block
    idx_noise_sector_tot = union(idx_noise_sector_tot,idx_noise_sector);
    
    % update progress bar
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
    
end

%% COMPUTE & DISPLAY BAD TRANSMIT PERCENTAGE
bad_pings_percent = numel(idx_noise_sector_tot)/nb_pings_tot*100;
if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText(sprintf('%.1f%% of bad pings',bad_pings_percent));
end
output_struct.idx_noise_sector=idx_noise_sector_tot;

tag = trans_obj.Bottom.Tag;
if isempty(p.Results.reg_obj)
    tag = ones(size(tag));
else
    tag = trans_obj.Bottom.Tag;
end
tag(output_struct.idx_noise_sector) = 0;

trans_obj.Bottom.Tag = tag;

output_struct.done =  true;

end


