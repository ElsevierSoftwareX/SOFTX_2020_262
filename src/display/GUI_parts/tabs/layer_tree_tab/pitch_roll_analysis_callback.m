%% pitch_roll_analysis_callback.m
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
% * |src|: TODO: write description and info on variable
% * |table|: TODO: write description and info on variable
% * |main_figure|: Handle to main ESP3 window
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel).
% * 2017-04-01: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function pitch_roll_analysis_callback(src,~,main_figure,IDs)

 layers=get_esp3_prop('layers');
    layer=get_current_layer();

    curr_disp=get_esp3_prop('curr_disp');

   
    if isempty(layer)
        return;
    end
    
    if numel(IDs)<2
        return;
    end
    pitch_av=nan(1,numel(IDs));
    pitch_std=nan(1,numel(IDs));
    pitch_grad_av=nan(1,numel(IDs));
    roll_av=nan(1,numel(IDs));
    roll_std=nan(1,numel(IDs));
    roll_grad_av=nan(1,numel(IDs));
    bad_ping_pc=nan(1,numel(IDs));
    heave_av=nan(1,numel(IDs));
    heave_std=nan(1,numel(IDs));
    heave_grad_av=nan(1,numel(IDs));
    for i=1:numel(IDs)

        [idx,~]=find_layer_idx(layers,IDs{i});
       
        layer_curr=layers(idx);
        
        [trans_obj,idx_freq]=layer_curr.get_trans(curr_disp);
 
        bad_ping_pc(i)=trans_obj.get_badtrans_perc();
        
        [pitch_av(i),pitch_std(i),pitch_grad_av(i),roll_av(i),roll_std(i),roll_grad_av(i),heave_grad_av(i)]=layer_curr.produce_pitch_roll_analysis();
        
    end

    
    hfig=new_echo_figure(main_figure,'Tag','pitchrollanalysis','Name','Picth/Roll Analysis');
     ax_0= axes(hfig,'nextplot','add','OuterPosition',[0 0.75 1 0.25]);
    yyaxis(ax_0,'left');
    ax_0.YAxis(1).Color = 'r';
    plot(ax_0,roll_std,'-^r');
    ax_0.YAxis(1).TickLabelFormat  = '%.1fm';
    ylabel(ax_0,'Heave Std (m)');
    
      
    yyaxis(ax_0,'right');
    plot(ax_0,roll_grad_av,'-sk');
    ax_0.YAxis(2).Color = 'k';
    ax_0.YAxis(2).TickLabelFormat  = '%.1fm/s';
    ylabel(ax_0,'Average Heave Change rate');
    grid(ax_0,'on');
    box(ax_0,'on');
    
    
    
    ax_1= axes(hfig,'nextplot','add','OuterPosition',[0 0.5 1 0.25]);
    yyaxis(ax_1,'left');
    ax_1.YAxis(1).Color = 'r';
    plot(ax_1,roll_std,'-^r');
    ax_1.YAxis(1).TickLabelFormat  = '%g^\\circ';
    ylabel(ax_1,'Roll Std (deg)');
    
      
    yyaxis(ax_1,'right');
    plot(ax_1,roll_grad_av,'-sk');
    ax_1.YAxis(2).Color = 'k';
    ax_1.YAxis(2).TickLabelFormat  = '%g^\\circ/s';
    ylabel(ax_1,'Average Roll Change rate');
    grid(ax_1,'on');
    box(ax_1,'on');
    
    ax= axes(hfig,'nextplot','add','OuterPosition',[0 0.25 1 0.25]);
    yyaxis(ax,'left');
    ax.YAxis(1).Color = 'r';
    plot(ax,pitch_std,'-^r');
    ax.YAxis(1).TickLabelFormat  = '%g^\\circ';
    ylabel(ax,'Pitch Std (deg)');
    
    
    
    yyaxis(ax,'right');
    plot(ax,pitch_grad_av,'-sk');
    ax.YAxis(2).Color = 'k';
    ax.YAxis(2).TickLabelFormat  = '%g^\\circ/s';
    ylabel(ax,'Average Pitch Change rate');
    grid(ax,'on');
    box(ax,'on');
    
    
    ax_2=axes(hfig,'nextplot','add','OuterPosition',[0 0 1 0.25]);
    plot(ax_2,bad_ping_pc,'-xb');
    ax_2.YAxis(1).Color = 'k';
    ax_2.YAxis(1).TickLabelFormat  = '%.0f ';
    ylabel(ax_2,'Bad Ping Percentage');
    grid(ax_2,'on');
    box(ax_2,'on');
    linkaxes([ax ax_1 ax_2],'x')
    ax.XLim=([1 numel(pitch_grad_av)]);
    xlabel(ax_2,'Transect Number');
    
    P_roll_1 = polyfit(bad_ping_pc,roll_std,1);
    P_roll = polyfit(bad_ping_pc,roll_grad_av,1);
    x_bad=nanmin(bad_ping_pc):nanmax(bad_ping_pc);
    hfig_2=new_echo_figure(main_figure,'Tag','rollbadanalysis','Name','Roll change rate against Bad Pings');
    ax_3= axes(hfig_2,'nextplot','add','OuterPosition',[0 0 1 1]);
    yyaxis(ax_3,'left');
    ax_3.YAxis(1).Color = 'b';
    plot(ax_3,bad_ping_pc,roll_grad_av,'.b');
    plot(ax_3,x_bad,polyval(P_roll,x_bad));
    ylabel(ax_3,'Average Roll Change rate');
    yyaxis(ax_3,'right');
    ax_3.YAxis(2).Color = 'r';
    plot(ax_3,bad_ping_pc,roll_std,'.r');
    plot(ax_3,x_bad,polyval(P_roll_1,x_bad));
    xlabel(ax_3,'Bad Ping Percentage');

    title(ax_3,sprintf('Corr (Pearson) with change rate: %.2f\n Corr (Pearson) with std: %.2f\n',corr(bad_ping_pc',roll_grad_av'),corr(bad_ping_pc',roll_std')));
    grid(ax_3,'on');
    box(ax_3,'on');
    axis(ax_3,'square');
    
    
    P_pitch_1 = polyfit(bad_ping_pc,pitch_std,1);
    P_pitch = polyfit(bad_ping_pc,pitch_grad_av,1);
    hfig_3=new_echo_figure(main_figure,'Tag','pitchbadanalysis','Name','Pitch change rate against Bad Pings');
    ax_4= axes(hfig_3,'nextplot','add','OuterPosition',[0 0 1 1]);
    yyaxis(ax_4,'left');
    ax_4.YAxis(1).Color = 'b';
    plot(ax_4,bad_ping_pc,pitch_grad_av,'.b');
    plot(ax_4,x_bad,polyval(P_pitch,x_bad));
    ylabel(ax_4,'Average Pitch Change rate');
    yyaxis(ax_4,'right');
    ax_4.YAxis(2).Color = 'r';
    plot(ax_4,bad_ping_pc,pitch_std,'.r');
    plot(ax_4,x_bad,polyval(P_pitch_1,x_bad));
    ylabel(ax_4,'Pitch Std');
    title(ax_4,sprintf('Corr (Pearson) with change rate: %.2f\n Corr (Pearson) with std: %.2f\n',corr(bad_ping_pc',pitch_grad_av'),corr(bad_ping_pc',pitch_std')));
    xlabel(ax_4,'Bad Ping Percentage');
    
    grid(ax_4,'on');
    box(ax_4,'on');
    axis(ax_4,'square');
    
    
        P_Heave_1 = polyfit(bad_ping_pc,abs(heave_std),1);
    P_Heave = polyfit(bad_ping_pc,abs(heave_grad_av),1);
    hfig_5=new_echo_figure(main_figure,'Tag','Heavebadanalysis','Name','Heave change rate (m/s) against Bad Pings');
    ax_5= axes(hfig_5,'nextplot','add','OuterPosition',[0 0 1 1]);
    yyaxis(ax_5,'left');
    ax_5.YAxis(1).Color = 'b';
    plot(ax_5,bad_ping_pc,abs(heave_grad_av),'.b');
    plot(ax_5,x_bad,polyval(P_Heave,x_bad));
    ylabel(ax_5,'Average Heave Change rate');
    yyaxis(ax_5,'right');
    ax_5.YAxis(2).Color = 'r';
    plot(ax_5,bad_ping_pc,abs(heave_std),'.r');
    plot(ax_5,x_bad,polyval(P_Heave_1,x_bad));
    ylabel(ax_5,'Heave Std');
    title(ax_5,sprintf('Corr (Pearson) with change rate: %.2f\n Corr (Pearson) with std: %.2f\n',corr(bad_ping_pc',abs(heave_grad_av)'),corr(bad_ping_pc',abs(heave_std'))));
    xlabel(ax_5,'Bad Ping Percentage');
    
    grid(ax_5,'on');
    box(ax_5,'on');
    axis(ax_5,'square');
    
    set_esp3_prop('layers',layers);
    
    
    
 

end

