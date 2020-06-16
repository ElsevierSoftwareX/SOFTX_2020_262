function output_struct = compute_bottom_features(trans_obj,varargin)

global DEBUG;
%DEBUG = true;

p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'thr_sv',-70,@isnumeric);
addParameter(p,'bot_feat_comp_method','Echoview',@(x) ismember(x,{'Echoview' 'Yoann' 'Rudy Kloser'}));
addParameter(p,'bot_ref_depth',100,@isnumeric);
addParameter(p,'thr_cum',95,@isnumeric);
addParameter(p,'thr_cum_max',100-1e-2,@isnumeric);
addParameter(p,'estimated_slope',5,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
parse(p,trans_obj,varargin{:});

%% prep

% data used
if p.Results.denoised
    field = 'svdenoised';
else
    field = 'sv';
end
if ~ismember(field,trans_obj.Data.Fieldname)
    field = 'sv';
end

% pings indices
if isempty(p.Results.reg_obj)
    idx_pings = 1:length(trans_obj.get_transceiver_pings());
    reg_obj = region_cl('Name','Temp','Idx_r',[1 10],'Idx_pings',idx_pings);
else
    reg_obj = p.Results.reg_obj;
end
idx_pings = reg_obj.Idx_pings;

% initialize results
output_struct.done = false;
output_struct.E1 = -999.*ones(size(idx_pings));
output_struct.E2 = -999.*ones(size(idx_pings));

if isempty(idx_pings)
    output_struct.done = true;
    return;
end
idx_pings = trans_obj.get_transceiver_pings(idx_pings);

% get bottom range, and pings with valid bottom (and not a badping)
bot_idx = trans_obj.get_bottom_idx(idx_pings);
bot_r   = trans_obj.get_bottom_range(idx_pings);
idx_bad = trans_obj.get_badtrans_idx(idx_pings);
bot_r(idx_bad) = NaN;
idx_val = find(~isnan(bot_r));

if isempty(idx_val)
    output_struct.done = true;
    return;
end

% get range for each sample
range_tot = trans_obj.get_transceiver_range();

% calculate pulse range
[p_sec, p_nsamp] = trans_obj.get_pulse_length(idx_pings);
p_r = range_tot(p_nsamp)';

p_r(p_r==0) = range_tot(p_nsamp(p_r==0)+1)';


% some initialization required in one method
switch p.Results.bot_feat_comp_method
    case 'Yoann'
        bottom_slope_across = nan(size(idx_pings));
        bottom_slope_along = nan(size(idx_pings));
        delta_along = nan(size(idx_pings));
        delta_across = nan(size(idx_pings));
        phi_slope_along = nan(size(idx_pings));
        phi_slope_across = nan(size(idx_pings));
end


% progress bar
load_bar_comp = p.Results.load_bar_comp;
if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(idx_val), 'Value',0);
end

% results display
if DEBUG
    
    % signal and echoes display
    f = new_echo_figure([],'tag','E1E2');
    ax = axes(f,'outerposition',[0 0 1 1],'XGrid','on','Ygrid','on','nextplot','add');
    plot_entire_ping = plot(ax,nan,nan,'k');
    plot_first_echo  = plot(ax,nan,nan,'-b');
    plot_E1          = plot(ax,nan,nan,'-b','LineWidth',4);
    plot_E2          = plot(ax,nan,nan,'-r','LineWidth',4);
    xlabel(ax,'Sample Number');
    ylabel(ax,'Sv');
    
    % angle displays
    switch p.Results.bot_feat_comp_method
        case 'Yoann'
            angle_fig = new_echo_figure([]);
    end
    
end


%% processing per valid ping
for ii = idx_val
    c=trans_obj.get_soundspeed(p_nsamp(ii));
    % different methods to find the start and end of the portions of the
    % signal to integrate
    switch p.Results.bot_feat_comp_method
        
        case 'Yoann'
            
            % bottom detection is the start of the echo
            idx_echo_start = bot_idx(ii);
            
            % calculate geometrically the distance of echo along the axis (in m)
            theta = trans_obj.Config.BeamWidthAthwartship; % beamwidth
            beta  = nanmax(p.Results.estimated_slope,2*theta); % incident angle
            echolength_theory = echo_length(p_r(ii),theta,beta,bot_r(ii));
            
            % find index of that theoretical echo end
            if ~isinf(echolength_theory)
                [~,idx_echo_end] = nanmin(abs( range_tot-(bot_r(ii)+echolength_theory) ));
            else
                idx_echo_end = numel(range_tot);
            end
            idx_echo = (idx_echo_start:idx_echo_end)';
            
            % get the echo signal and phase
            sv_first_echo = (trans_obj.Data.get_subdatamat(idx_echo,idx_pings(ii),'field',field));
            [al_phi,ac_phi] = trans_obj.get_phase('idx_ping',idx_pings(ii),'idx_r',idx_echo);

            % calculate phase angles 
            idx_tmp = find(sv_first_echo > nanmax(sv_first_echo)-20);
            if isempty(idx_tmp)
                continue;
            end
            
            if ~isempty(al_phi)&&~isempty(ac_phi)
                [~,delta_along(ii),phi_slope_along(ii),phi_est_along] = est_phicross_fft(idx_tmp,db2pow_perso(sv_first_echo(idx_tmp)),al_phi(idx_tmp),0);
                [~,delta_across(ii),phi_slope_across(ii),phi_est_across] = est_phicross_fft(idx_tmp,db2pow_perso(sv_first_echo(idx_tmp)),ac_phi(idx_tmp),0);
            else
                delta_along(ii)=nan;phi_slope_along(ii)=nan;
                phi_est_along=nan(size(sv_first_echo(idx_tmp)));
                delta_across(ii)=nan;phi_slope_across(ii)=nan;
                phi_est_across=nan(size(sv_first_echo(idx_tmp)));
            end
            
            if DEBUG
                figure(angle_fig);
                clf;
                
                ax21 = subplot(3,1,1);
                hold on; plot(idx_echo,al_phi)  
                plot(idx_echo(idx_tmp),al_phi(idx_tmp),'k.')
                plot(idx_echo(idx_tmp),phi_est_along,'r');
                grid on;
                set(gca,'fontsize',16);
                xlabel('Sample number');
                ylabel('Phase deg.');
                title(['Along: Std Fit ' num2str(delta_along(ii)) ' deg.'])
                
                ax23 = subplot(3,1,2);
                hold on;plot(idx_echo,ac_phi)
                plot(idx_echo(idx_tmp),ac_phi(idx_tmp),'k.')
                plot(idx_echo(idx_tmp),phi_est_across,'r');
                grid on;
                set(gca,'fontsize',16);
                xlabel('Sample number');
                ylabel('Phase deg.');
                title(['Across: Std Fit ' num2str(delta_across(ii)) ' deg.'])
                
                ax8 = subplot(3,1,3);
                plot(idx_echo,sv_first_echo)
                hold on;
                plot(idx_echo(idx_tmp),sv_first_echo(idx_tmp),'k.')
                grid on;
                set(gca,'fontsize',16);
                xlabel('Sample number');
                ylabel('Sv(dB)');
            end

            % convert to seafloor slope
            if contains(trans_obj.Config.TransceiverName,{'ES60' 'ES70' 'ER60'})
                angle_slope_along  = (phi_slope_along(ii)./(trans_obj.Config.AngleSensitivityAthwartship*127/180)-trans_obj.Config.AngleOffsetAlongship);
                angle_slope_across = (phi_slope_across(ii)./(trans_obj.Config.AngleSensitivityAthwartship*127/180)-trans_obj.Config.AngleOffsetAthwartship);
            else
                angle_slope_along  = (phi_slope_along(ii)./trans_obj.Config.AngleSensitivityAthwartship-trans_obj.Config.AngleOffsetAlongship);
                angle_slope_across = (phi_slope_across(ii)./trans_obj.Config.AngleSensitivityAthwartship-trans_obj.Config.AngleOffsetAthwartship);
            end
            dr = nanmean(diff(range_tot(idx_echo))); % inter-sample range in m
            r  = nanmean(range_tot(idx_tmp));
            if numel(idx_tmp) > 4*p_nsamp(ii)
                if delta_along(ii)<45
                    bottom_slope_along(ii) = atand(1/((1+dr/r/2)*cosd(angle_slope_along)- 1)*((1+dr/r/2)*sind(angle_slope_along)));
                end
                if delta_across(ii)<45
                    bottom_slope_across(ii) = atand(1/((1+dr/r/2)*cosd(angle_slope_across)- 1)*((1+dr/r/2)*sind(angle_slope_across)));
                end
            end
            est_slope = sqrt(nansum([bottom_slope_along(ii)^2 bottom_slope_across(ii)^2]));
            
            % recalculate theoretical echo footprint with that improved
            % bottom slope estimation. Limit low values to aperture
            est_slope = nanmax(est_slope,2*theta);
            echolength_theory = echo_length(p_r(ii),theta,est_slope,bot_r(ii));
            
            % find index of that theoretical echo end
            idx_echo_end_ori = idx_echo_end;
            %idx_echo_ori = idx_echo;
            if ~isinf(echolength_theory)
                [~,idx_echo_end] = nanmin(abs( range_tot-(bot_r(ii)+echolength_theory) ));
            else
                idx_echo_end = numel(range_tot);
            end
            idx_echo = idx_echo_start:idx_echo_end;
            
            if idx_echo_end > idx_echo_end_ori
                % echo is longer than previous estimate, get data again
                sv_first_echo = (trans_obj.Data.get_subdatamat(idx_echo,idx_pings(ii),'field',field));
            else
                % echo is shorter, just sample the first data
                sv_first_echo = sv_first_echo(1:idx_echo_end-idx_echo_start+1);
            end
            
            sv_first_echo(sv_first_echo==-999) = nan;
            
            % define the tail as an interval of the cumulative power
            sv_first_echo = db2pow_perso(sv_first_echo);
            ncs = cumsum(sv_first_echo,'omitnan')./nansum(sv_first_echo); % normalized cumulative distribution
            idx_E1 = (ncs>=p.Results.thr_cum/100) & (ncs<=p.Results.thr_cum_max/100);
            if ~any(idx_E1)
                % if echo is too short, this double interval may be too small to
                % return a result. Use only the first parameter
                idx_E1 = ncs>=p.Results.thr_cum/100;
            end
            
            E1_start_idx = find(idx_E1,1, 'first') + idx_echo_start;
            E1_end_idx   = find(idx_E1,1, 'last') + idx_echo_start;
            
            % second echo at twice the range of the first. Use bottom
            % detect and end of tail of first echo as limits.
            E2_start_idx = 2.*idx_echo_start;
            E2_end_idx   = 2.*E1_end_idx;
            
            % no attempt for depth normalization here
            depth_normalizing_factor = 1;
            
        case 'Rudy Kloser'
            
            % version 1:
            % Kloser, R.J., Bax, N.J. Ryan, T.E. Williams A. and Barker B.A. 2001.
            % Remote sensing of seabed types in the Australian South East Fishery;
            % development and application of normal incident acoustic techniques and
            % associated ‘ground truthing’. Marine and Freshwater Research, 52: 475-89
            %
            % The tail is defined by hard-coded start and end angles (theta_i). They
            % are described as delimiting the "off axis angular values", and
            % "referenced to the start of the bottom echo". There is also a pulse
            % offset, 0 for  the start, and 1.5m for the end for a 1ms pulse, implying
            % it's calculated as c*tau. No idea why not c*tau/2. These are plugged into
            % an equation that returns the distances (d_i, in m) corresponding to those
            % angles.
            %
            % The second echo is defined as starting twice the depth of the
            % start of the first, and ending a hard-coded distance later.
            
%             theta_i = [20, 30];
%             pulse_offset = [zeros(size(p_sec(ii))); c.*p_sec(ii)];
%             d_i = bot_r(ii).*(1./cosd(theta_i')-1) + pulse_offset;
%             length_E2_m = 30; % in m
%             
            % version 2:
            % The algorithm is slighlty different in Kloser's thesis "Seabed Biotope
            % Characterisation Based On Acoustic Sensing".
            theta_i = [20, 32];
            pulse_offset = c.*ones(2,1)*p_sec(ii); % pulse offset is same for the two angle now
            d_i = bot_r(ii).*(1./cosd(theta_i')-1) + pulse_offset;
            length_E2_m = 20; % in m
            
            % turn to index
            [~,E1_start_idx] = nanmin(abs( range_tot-(bot_r(ii)+d_i(1)) ));
            [~,E1_end_idx]   = nanmin(abs( range_tot-(bot_r(ii)+d_i(2)) ));
            idx_echo_start = bot_idx(ii);
            idx_echo_end = E1_end_idx;
            
            % "The second echo was integrated at two times the water depth
            % (d1) and ending at two times water depth plus 20 m (d2)."
            [~,E2_start_idx] = nanmin(abs(range_tot-(2.*bot_r(ii))));
            [~,E2_end_idx]   = nanmin(abs(range_tot-(2.*bot_r(ii)+length_E2_m)));

            % no attempt for depth normalization here
            depth_normalizing_factor = 1;
            
        case 'Echoview'
            
            % two hard-coded parameters I'm unsure how to define
            Reference_Depth = p.Results.bot_ref_depth;         % for depth normalization. Not a big issue as long as we keep it constant
            Bottom_echo_threshold_value_1m = p.Results.thr_sv; % quite importantly define where the bottom echo ends...
            
            PulseLength = c.*p_sec(ii)./2;
            theta = trans_obj.Config.BeamWidthAthwartship;
            
            % echo could be seen to start at our bottom detection
            % idx_echo_start = bot_idx(ii);
            % but in echoview, the bottom line is at the first sample of
            % the first three consecutive sample at -60dB or above. Let's
            % find that index after the bottom line.
            
            % first, get ping data from the bottom line onwards
            sv_ping_after_bot = (trans_obj.Data.get_subdatamat(bot_idx(ii):numel(range_tot),idx_pings(ii),'field',field));
            if isempty(sv_ping_after_bot)
                continue;
            end
            
            % then, find the first set of three consecutive samples above
            % the threshold of -60dB
            detec = sv_ping_after_bot>=-60;
            idx_echo_start = find(conv(detec,[1,1,1])==3,1,'first')-2;
            if isempty(idx_echo_start)
                continue;
            end
            % the index in the full ping data is
            idx_echo_start = idx_echo_start + bot_idx(ii) - 1;
            
            % Use this for depth normalization
            Actual_Depth = range_tot(idx_echo_start);
            OffAxisPulseLength_Actual = PulseLength + Actual_Depth - Actual_Depth.*cosd(theta./2);
            OffAxisPulseLength_Ref    = PulseLength + Reference_Depth - Reference_Depth.*cosd(theta./2);
            depth_normalizing_factor = OffAxisPulseLength_Ref./OffAxisPulseLength_Actual;
            
            % For the start of E1 integration, the tail would normally
            % simply start after one pulse length, when the footprint stops
            % being a circle and starts being an annulus.
            % E1_start_depth = Actual_Depth + PulseLength;
            
            % But Echoview uses the strange concept of "off-axis offset" or
            % "effective pulse length": the idea that, at the edge of the
            % beam, the pulse "has to travel longer in the substrate". No
            % idea why this would affect the start of the tail... Anyway,
            % it's unfortunately defined in two different manners. On one
            % page, it's expressed as an equation that basically says it's
            % the range at the edge of the beam (???). Applying it
            % without the transducer draft is:
            % E1_start_depth = (Actual_Depth + PulseLength)./cosd(theta./2);
            
            % The other is a sentence "The start point for the
            % calculation of Bottom_roughness is given by Bottom line depth
            % plus the distance of c*tau/2 plus the off-axis angle offset.
            % The offset accounts for the extra distance the complete pulse
            % has to travel in the substrate". Using their "off axis pulse
            % length" thing.
            E1_start_depth = Actual_Depth + OffAxisPulseLength_Actual;
            
            % In any case, the index is
            [~,E1_start_idx] = min(abs(range_tot-E1_start_depth));
            
            % The end of the interval for E1 integration is similar to how
            % the start of the echo was found. "The first of the three
            % consecutive samples below Bottom echo threshold at 1m (dB) is
            % the end of a valid bottom echo."
            detec = sv_ping_after_bot < Bottom_echo_threshold_value_1m;
            detec(1:E1_start_idx-bot_idx(ii)+1) = 0;
            E1_end_idx = find(conv(detec,[1,1,1])==3,1,'first')-2;
            % the index in the full ping data is
            E1_end_idx = E1_end_idx + bot_idx(ii) - 1;
            idx_echo_end = E1_end_idx;
            
            % Second echo is simply defined based on the start and end of
            % the first echo
            E2_start_idx = 2.*idx_echo_start;
            E2_end_idx   = 2.*E1_end_idx;
            
    end
    
    % E1 integration
    sv_E1 = (trans_obj.Data.get_subdatamat(E1_start_idx:E1_end_idx,idx_pings(ii),'field',field));
    sv_E1(sv_E1==-999) = NaN;
    E1 = depth_normalizing_factor.*log10(4*pi*(1852^2)*sum(db2pow_perso(sv_E1)));
    
    % E2 integration
    sv_E2 = (trans_obj.Data.get_subdatamat(E2_start_idx:E2_end_idx,idx_pings(ii),'field',field));
    sv_E2(sv_E2==-999) = NaN;
    E2 = depth_normalizing_factor.*log10(4*pi*(1852^2)*sum(db2pow_perso(sv_E2)));
    
    % saving
    output_struct.E1(1,ii) = E1;
    output_struct.E2(1,ii) = E2;
    
    % update progress bar
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ii);
    end
    
    if DEBUG
        % ping data
        sv_entire_ping = (trans_obj.Data.get_subdatamat([],idx_pings(ii),'field',field));
        num_samples = length(sv_entire_ping);
        
        % plot entire ping
        set(plot_entire_ping,'XData',1:length(sv_entire_ping),'ydata',sv_entire_ping);
        
        % plot full bottom echo
        if exist('idx_echo_end','var') && idx_echo_start<= num_samples
            xd = idx_echo_start:min([idx_echo_end, num_samples]);
            set(plot_first_echo,'XData',xd,'ydata',sv_entire_ping(xd));
        end
        
        % plot part of echo used for E1
        if E1_start_idx <= num_samples
            xd = E1_start_idx:min([E1_end_idx, num_samples]);
            set(plot_E1,'XData',xd,'ydata',sv_entire_ping(xd));
        end
        
        % plot part of the echo used for E2
        if E2_start_idx <= num_samples
            xd = E2_start_idx:min([E2_end_idx, num_samples]);
            set(plot_E2,'XData',xd,'ydata',sv_entire_ping(xd));
        end
        
        % finalize
        xlim(ax,[max([1 idx_echo_start-100]) min([E2_end_idx+100 num_samples])])
        ax.Title.String = sprintf('Ping number %d/%d. E1=%.4f. E2=%.4f',idx_pings(ii),idx_pings(idx_val(end)),E1,E2);
        drawnow
        
    end
    
end

output_struct.done =  true;
trans_obj.Bottom.E1(idx_pings)=output_struct.E1;
trans_obj.Bottom.E2(idx_pings)=output_struct.E2;


% %
% figure()
% plot(idx_pings,bottom_slope_across)
% hold on;
% plot(idx_pings,bottom_slope_along)
% legend({'Across' 'Along'})


