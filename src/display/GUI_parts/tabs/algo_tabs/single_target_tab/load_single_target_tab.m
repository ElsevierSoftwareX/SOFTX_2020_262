function load_single_target_tab(main_figure,algo_tab_panel)

algo_name='SingleTarget';

load_algo_panel('main_figure',main_figure,...
        'panel_h',uitab(algo_tab_panel),...
        'algo_name',algo_name,...
        'title','Single Targets',...
        'save_fcn_bool',true);

end






