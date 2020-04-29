function hfig=plot_survey_trans_result(surv_obj,hfig)

% plot_color={'k','r','g','m','y'};

trans_sum=surv_obj.SurvOutput.transectSum;

label=cell(1,length(trans_sum));

for j = 1:length(trans_sum.snapshot)
    label{j}=sprintf('S:%d St: %s T: %d ',trans_sum.snapshot(j),trans_sum.stratum{j},trans_sum.transect(j));
end

if ~isempty(hfig)&&ishandle(hfig)&&isvalid(hfig)
    figure(hfig);
else
    hfig=new_echo_figure([]);
end

ax=axes(hfig,'nextplot','add','XGrid','on','YGrid','on','box','on');

plot(ax,(trans_sum.abscf),'marker','s','color','k');
set(ax,'xtick',1:length(trans_sum.abscf));
ax.XAxis.TickLabelInterpreter='none';
set(ax,'xticklabel',label);
ax.XTickLabelRotation=90;
ylabel(ax,'s_a(m^2m^{-2})')

