function load_bottom_feature_tab(main_figure,algo_tab_panel)

tab_main=uitab(algo_tab_panel,'Title','Bottom Features');

algo_name= 'BottomFeatures';

load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Position',[0 0 0.5 1]),...
        'algo_name',algo_name,...
        'title','',...
        'save_fcn_bool',false);


end