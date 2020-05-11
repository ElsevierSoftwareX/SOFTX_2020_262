function idx_ringdown = analyse_ringdown(RingDown,rd_thr)

global DEBUG;

%% PREPROCESSING ON INPUT VARIABLES

% total number of pings
[nb_pings,idx_size] = max(size(RingDown));

% if data vector is wrong direction, fix it
if idx_size == 1
    RingDown = RingDown';
end

% data are supposed to be one sample per ping only. If input is more than one sample, compute the mean value per ping
if size(RingDown,1)>1 && size(RingDown,2)>1
    RingDownMean = 20*log10(nanmean(10.^(RingDown/20)));
else
    RingDownMean = RingDown;
end

% if input threhsold was zero, exit function here
if rd_thr == 0
    idx_ringdown = ones(size(RingDownMean));
    return;
end



%% FIRST ANALYSIS
% with fixed nominal value

% calculate histogram and find the bin with maximum number of values.
% This is our nominal value
bin = min(11,round(nb_pings/5));

[pdf_RD,x_RD] = pdf_perso(RingDownMean,'bin',2*bin);
[~,idx_max] = nanmax(pdf_RD);
RingDownNominal = x_RD(idx_max);

% flag as good all values that are different from the nonimal value by less than twice the threshold
idx_ringdown_1 = abs(RingDownMean-RingDownNominal) <= rd_thr*2;


%% SECOND ANALYSIS
% with variable nominal value

% first removing those flagged in first pass
RingDownMean2 = RingDownMean;
RingDownMean2(~idx_ringdown_1) = nan;

% sliding histogram
win = min(75,nb_pings);
spc = 1;
[s_pdf,~,y_value,~] = sliding_pdf((1:nb_pings),RingDownMean2,win,bin,spc,1);

% OBSOLETE CODE
% [~,idx_max]=nanmax(s_pdf);
% idx_high_p=s_pdf<=(0.1*repmat(s_pdf(idx_max+(bin*(0:nb_pings-1))),size(s_pdf,1),1));
% y_value(idx_high_p)=nan;

% for each ping, computing the average of the three most common values in the sliding histogram as the "Most Probable Value" 
[~,idx_sort] = sort(s_pdf,1,'descend');
idx_sort = idx_sort + ones(bin,1)*(0:size(idx_sort,2)-1)*bin;
y_value_sorted = y_value(idx_sort);
nb_keep=nanmin(size(y_value_sorted,1),3);
RingDownMPV = nanmean(y_value_sorted(1:nb_keep,:));

% flag as good all values for whom difference with the sliding MPV is less than the threshold
idx_ringdown_2 = abs(RingDownMean2-RingDownMPV) < rd_thr;


%% COMBINING RESULTS
% also keep pings whose ringdown value is one of the three most common
% values in the sliding histogram
idx_ringdown = ( idx_ringdown_2 & idx_ringdown_1 ) | nansum( bsxfun(@eq,RingDownMean2,y_value_sorted(1:nb_keep,:)) ) > 0;


if DEBUG
    
    figure();
    
    % ringdown analysis 1
    subplot(221);
    plot([1,length(RingDownMean)],RingDownNominal.*ones(1,2),'r','LineWidth',2);
    hold on
    plot([1,length(RingDownMean)],(RingDownNominal+rd_thr*2).*ones(1,2),'r--','LineWidth',2);
    plot([1,length(RingDownMean)],(RingDownNominal-rd_thr*2).*ones(1,2),'r--','LineWidth',2);
    plot(RingDownMean,'.-');
    plot(find(~idx_ringdown_1),RingDownMean(~idx_ringdown_1),'kx');
    title('Ringdown analysis #1')
    xlabel('ping #');
    ylabel ('power (dB)');
    grid on
    
    % histo for ringdown analysis 1
    subplot(223);
    bar(x_RD,pdf_RD)
    set(gca,'Yscale','log')
    hold on
    plot(x_RD(idx_max),pdf_RD(idx_max),'k*');
    legend('ringdown histogram','nominal value','Location','NorthWest')
    title('Ringdown analysis #1')
    xlabel('power (dB)')
    ylabel('count #')
    grid on

    % ringdown analysis 2
    subplot(222)
    plot(RingDownMean2,'.-');
    hold on;
    plot(RingDownMPV,'-r');
    plot(RingDownMPV-rd_thr,'--r');
    plot(RingDownMPV+rd_thr,'--r');
    plot(find(~idx_ringdown_2),RingDownMean2(~idx_ringdown_2),'kx');
    grid on;
    xlabel('ping #');
    ylabel('power (dB)');
    grid on;
    title('Ringdown analysis #2 (sliding histogram)')

    % final results
    subplot(224)
    plot(RingDownMean,'.-');
    hold on;
    plot(find(~idx_ringdown),RingDownMean(~idx_ringdown),'kx');
    grid on;
    xlabel('ping #');
    ylabel('power (dB)');
    grid on;
    title('Ringdown analysis (total)')
    
end



end