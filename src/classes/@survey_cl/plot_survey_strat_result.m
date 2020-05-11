function hfig = plot_survey_strat_result(surv_obj,hfig)

plot_color = {'k',[0.8 0 0],[0 0.8 0],[0 0 0.8],[0.8 0.8 0],'m'};
if ~isempty(hfig)&&ishandle(hfig)&&isvalid(hfig)
    figure(hfig);
else
    hfig = new_echo_figure([]);
end

ax = axes(hfig,'nextplot','add','XGrid','on','YGrid','on','box','on');


strats = [];
strat_sum = cell(1,numel(surv_obj));
for isur = 1:length(surv_obj)
    strat_sum{isur} = surv_obj(isur).SurvOutput.stratumSum;
    strats = unique(union(strats,strat_sum{isur}.stratum));
end

icol = 0;
iled = 0;

snap_table=[];
for isur = 1:length(surv_obj)
    struct_to_store = surv_obj(isur).SurvOutput.stratumSum;
    struct_to_store.Title = cell(1,numel(struct_to_store.snapshot));
    struct_to_store.Title(:) = {surv_obj(isur).SurvInput.Infos.Title};
    snaps = unique(strat_sum{isur}.snapshot);
    T=struct2table(structfun(@transpose,struct_to_store,'UniformOutput',false),'AsArray',0);
    snap_table=[snap_table;T];
    for ii = 1:numel(snaps)
        iled = iled+1;
        legend_name{iled} = sprintf('%s: Snapshot %d',surv_obj(isur).SurvInput.Infos.Title,snaps(ii));
        icol = rem(icol+1,numel(plot_color));
        icol(icol == 0) = numel(plot_color);
            abscf_mean{ii} = nan(1,numel(strats));
            abscf_std{ii} = nan(1,numel(strats));
            snap_strat{ii} = strats;
        for jj = 1:length(strats)
            idx = (strat_sum{isur}.snapshot == snaps(ii)&strcmp(strat_sum{isur}.stratum,strats{jj}));

            if any(idx)
                abscf_mean{ii}(jj) = strat_sum{isur}.abscf_wmean(idx);
                abscf_std{ii}(jj) = sqrt(strat_sum{isur}.abscf_var(idx));
            end
        end    
        errorbar(ax,abscf_mean{ii},abscf_std{ii},'marker','s','color',plot_color{icol});
    end    
      
end

set(ax,'xtick',1:length(strats));
set(ax,'xticklabel',strats);
ylabel(ax,'s_a(m^2m^{-2})')
xlabel(ax,'Stratum Name');
legend(ax,legend_name,'interpreter','none');

% [G_t,tt]=findgroups(snap_table(:,{'Title'}));
% 
% for ui=1:numel(tt)
%     
% end





end