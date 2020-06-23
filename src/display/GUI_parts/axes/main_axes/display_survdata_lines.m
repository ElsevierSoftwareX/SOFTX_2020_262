function display_survdata_lines(main_figure)

axes_panel_comp=getappdata(main_figure,'Axes_panel');
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);


ax=axes_panel_comp.echo_obj.main_ax;
xdata=trans_obj.get_transceiver_pings();
%ydata=trans_obj.get_transceiver_samples();

vis=curr_disp.DispSurveyLines;

u=findobj(ax,'Tag','surv_id');
delete(u);

Time=trans_obj.Time;
idx_start_time=[];
idx_end_time=[];

if length(layer.SurveyData)>=1
    idx_start_time=nan(1,length(layer.SurveyData));
    idx_end_time=nan(1,length(layer.SurveyData));
    for is=1:length(layer.SurveyData)
        surv_temp=layer.get_survey_data('Idx',is);
        if ~isempty(surv_temp)
            idx_start_time_tmp=find((surv_temp.StartTime-Time)<0,1);
            idx_end_time_tmp=find((surv_temp.EndTime-Time)<=0,1);
            if ~isempty(idx_start_time_tmp)
                idx_start_time(is)=idx_start_time_tmp;
            else
                idx_start_time(is)=1;
            end
            if ~isempty(idx_end_time_tmp)
                idx_end_time(is)=idx_end_time_tmp;
            else
                 idx_end_time(is)=numel(Time);
            end
        end
    end
end
dt=1;

for ifile=1:length(idx_start_time)
    surv_temp=layer.get_survey_data('Idx',ifile);
    if ~isempty(idx_start_time(ifile))
        xline(ax,xdata(idx_start_time(ifile))-dt/4,'color',[0 0.5 0],'tag','surv_id','Visible',vis,'Label',surv_temp.print_survey_data,'Interpreter','none');
        %plot(ax,xdata(idx_start_time(ifile)).*ones(size(ydata))-dt/4,ydata,'color',[0 0.5 0],'tag','surv_id','Visible',vis);
    end
end

for ifile=1:length(idx_end_time)
    if ~isempty(idx_end_time(ifile))
        xline(ax,xdata(idx_end_time(ifile))+dt/4,'r','tag','surv_id','Visible',vis,'Interpreter','none');
        %plot(ax,xdata(idx_end_time(ifile)).*ones(size(ydata))+dt/4,ydata,'r','tag','surv_id','Visible',vis);
    end
end

end