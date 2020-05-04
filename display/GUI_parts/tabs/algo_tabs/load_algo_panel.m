function panel_comp=load_algo_panel(varargin)
esp3_obj=getappdata(groot,'esp3_obj');

if isempty(esp3_obj)
    main_figure_def=[];
else
    main_figure_def=esp3_obj.main_figure;
end

p = inputParser;

addParameter(p,'main_figure',main_figure_def,@(x)isempty(x)||ishandle(x));
addParameter(p,'panel_h',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'input_struct_h',[],@(x) isstruct(x)||isempty(x));
addParameter(p,'algo_name','',@ischar);
addParameter(p,'title','',@ischar);
addParameter(p,'save_fcn_bool',true,@islogical);
parse(p,varargin{:});

main_figure=p.Results.main_figure;
panel_h=p.Results.panel_h;
algo_name=p.Results.algo_name;
title=p.Results.title;
save_fcn_bool=p.Results.save_fcn_bool;
input_struct_h=p.Results.input_struct_h;


algo_panels=getappdata(main_figure,'Algo_panels');

if ~isempty(algo_panels)
    algo_panels(~isvalid(algo_panels))=[];
end

if ~isempty(algo_panels)
    [~,idx_same]=algo_panels.get_algo_panel(algo_name);
    delete(algo_panels(idx_same));
    algo_panels(idx_same)=[];
end

if save_fcn_bool
    panel_comp=algo_panel_cl('container',panel_h,...
        'title',title,...
        'algo',algo_cl('Name',algo_name),...
        'input_struct_h',input_struct_h,...
        'apply_cback_fcn',{@validate,main_figure,algo_name,'current'},...
        'save_cback_fcn',{@save_display_algos_config_callback,main_figure,algo_name},...
        'save_as_cback_fcn',{@save_new_display_algos_config_callback,main_figure,algo_name},...
        'delete_cback_fcn',{@delete_display_algos_config_callback,main_figure,algo_name}...
        );
else
    panel_comp=algo_panel_cl('container',panel_h,...
        'title',title,...
        'algo',algo_cl('Name',algo_name),...
        'input_struct_h',input_struct_h,...
        'apply_cback_fcn',{@validate,main_figure,algo_name,'current'},...
        'save_cback_fcn',{@save_display_algos_config_callback,main_figure,algo_name});
end

if ~isempty(algo_panels)
    algo_panels(numel(algo_panels)+1)=panel_comp;
else
    algo_panels=panel_comp;
end

setappdata(main_figure,'Algo_panels',algo_panels);

end

function  validate(~,~,main_figure,algo_name,str)
update_algos(main_figure,'algo_name',{algo_name});

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
load_bar_comp=getappdata(main_figure,'Loading_bar');
show_status_bar(main_figure);

if isempty(layer)
    return;
end

switch str
    case 'current'
        [trans_obj,idx_chan]=layer.get_trans(curr_disp);
    otherwise
        [trans_obj,~]=layer.get_trans(curr_disp);
        idx_chan = 1:numel(layer.Frequencies);
end
update_algos(main_figure,'algo_name',{algo_name},'idx_chan',idx_chan);

switch algo_name
    
    case 'Classification'
        update_survey_opts(main_figure);
         
        old_regs=trans_obj.Regions;
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        
        add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);
        
        update_multi_freq_disp_tab(main_figure,'sv_f',0);
        update_multi_freq_disp_tab(main_figure,'ts_f',0);
        
        hide_status_bar(main_figure);
        
        display_regions(main_figure,'both');
        curr_disp.setActive_reg_ID(trans_obj.get_reg_first_Unique_ID());

        update_echo_int_tab(main_figure,0);
        
    case {'BottomDetection' 'BottomDetectionV2'}
        
        old_bot=trans_obj.Bottom;
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        hide_status_bar(main_figure);
        
        set_current_layer(layer);
        
        bot=trans_obj.Bottom;
        add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
        
        set_alpha_map(main_figure,'update_bt',0);
        display_bottom(main_figure);
        order_stacks_fig(main_figure,curr_disp);
        
    case 'Denoise'
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        hide_status_bar(main_figure);
        curr_disp.setField('svdenoised');
        
    case {'BadPingsV2' 'SpikesRemoval' 'DropOuts'}
        
        old_bot = trans_obj.Bottom;
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp,'replace_bot',0);
        
        hide_status_bar(main_figure);
        
        bot = trans_obj.Bottom;
        
        add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);
        
        set_alpha_map(main_figure,'update_cmap',0,'update_under_bot',0);
        display_bottom(main_figure);
        
        
    case 'SchoolDetection'
        
        old_regs=trans_obj.Regions;
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        
        add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);
        
        update_multi_freq_disp_tab(main_figure,'sv_f',0);
        update_multi_freq_disp_tab(main_figure,'ts_f',0);
        
        hide_status_bar(main_figure);
        
        display_regions(main_figure,'both');
        curr_disp.setActive_reg_ID(trans_obj.get_reg_first_Unique_ID());
        
        
    case 'SingleTarget'
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        
        hide_status_bar(main_figure);
        
        curr_disp.setField('singletarget');
        
        display_tracks(main_figure);
        update_st_tracks_tab(main_figure,'histo',1,'st',1);
        
        
    case 'TrackTarget'
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        hide_status_bar(main_figure);
        if~isempty(layer.Curves)
            layer.Curves(contains({layer.Curves(:).Unique_ID},'track'))=[];
        end
        set_current_layer(layer);
        display_tracks(main_figure);
        update_multi_freq_disp_tab(main_figure,'ts_f',1);
        update_st_tracks_tab(main_figure,'histo',1,'st',0);
        
    case 'BottomFeatures'
        
        layer.apply_algo(algo_name,'idx_chan',idx_chan,'load_bar_comp',load_bar_comp);
        hide_status_bar(main_figure);
        
        h_fig = new_echo_figure([],'Tag','E1/E2');
        
        ax1 =  axes(h_fig,'nextplot','add','OuterPosition',[0.05 0.55 0.9 0.45]);
        E1 = trans_obj.Bottom.E1;
        E1(E1==-999) = NaN;
        plot(ax1,E1,'b-');
        ylabel(ax1,'E1 (dB)');
        box(ax1,'on');
        grid(ax1,'on');
        xlabel(ax1,'Ping Number');
        xlim(ax1,[1 numel(E1)]);
        
        ax2 =  axes(h_fig,'nextplot','add','OuterPosition',[0.05 0.05 0.9 0.45]);
        E2= trans_obj.Bottom.E2;
        E2(E2==-999) = NaN;
        plot(ax2,E2,'r-');
        ylabel(ax2,'E2 (dB)');
        box(ax2,'on');
        grid(ax2,'on');
        xlabel(ax2,'Ping Number');
        xlim(ax2,[1 numel(E2)]);
        
end
order_stacks_fig(main_figure,curr_disp);
end