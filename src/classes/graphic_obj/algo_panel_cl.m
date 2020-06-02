classdef algo_panel_cl < dynamicprops
    properties
        algo
        title
        container
        default_params_h =[]
    end
    
    methods
        function obj=algo_panel_cl(varargin)
            
            p = inputParser;
            
            addParameter(p,'algo',algo_cl(),@(x) isa(x,'algo_cl'));
            addParameter(p,'title','',@ischar);
            addParameter(p,'container',[],@(x)isempty(x)||ishandle(x));
            addParameter(p,'input_struct_h',[],@(x) isstruct(x)||isempty(x));
            addParameter(p,'apply_cback_fcn',@do_nothing);
            addParameter(p,'save_cback_fcn',@do_nothing);
            addParameter(p,'save_as_cback_fcn',[]);
            addParameter(p,'delete_cback_fcn',[]);
            
            parse(p,varargin{:});
            
            results=p.Results;
            
            obj.algo=results.algo;
            
             param_names=obj.algo.Input_params.get_name();
             params_class=obj.algo.Input_params.get_class();
             nb_cell_params=sum(strcmpi(params_class,'cell'));
             nb_bool_params=sum(strcmpi(params_class,'logical'));
             
             if nb_cell_params>0
                 nb_c_min=2;
             else
                 nb_c_min=1;
             end
             nb_params = numel(param_names) + sum(strcmpi(params_class,'cell'));
             if ~isempty(results.input_struct_h)
                 nb_params =nb_params- sum(ismember(fieldnames(results.input_struct_h),param_names));
             end
             
             if isempty(results.save_as_cback_fcn)
                 nb_r_max =7;    
             else
                 nb_r_max =6;
             end
             
             nb_r_max_tot=8;
             
             nb_c=nanmax(ceil((nb_params-nb_bool_params+1)/nb_r_max),nb_c_min);
            
            gui_fmt=init_gui_fmt_struct();
            gui_fmt.txt_w=gui_fmt.txt_w*1.2;
            pos=create_pos_3(nb_r_max_tot,nb_c,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
            
            p_button=pos{nb_r_max_tot,1}{1};
            p_button(3)=gui_fmt.button_w;
  
            if isempty(results.container)
                obj.container = new_echo_figure([]);
            else      
                obj.container = results.container;
            end
           
            obj.container.Tag=obj.algo.Name;
            
            if isempty(results.title)
                obj.title = obj.algo.Name;
            else
                obj.title = results.title;
            end
            
            switch class(obj.container)
                case 'matlab.ui.Figure'
                    obj.container.Name=obj.title;
                otherwise
                    obj.container.Title=obj.title;
                    %txt_tmp = uicontrol(obj.container)
                    
            end
            
            obj.container.Tag=obj.algo.Name;
            
                      
            if ~isempty(results.save_as_cback_fcn)
                try
                    [~,~,algo_files]=get_config_files(obj.algo.Name);
                    [~,algo_alt,list_params]=read_config_algo_xml(algo_files{1});
                catch
                    algo=init_algos(obj.algo.Name);
                    write_config_algo_to_xml(algo,{'--'},0);
                    [~,algo_alt,list_params]=read_config_algo_xml(algo_files{1});
                end
                uicontrol(obj.container,gui_fmt.txtStyle,'String','Load Values','Position',pos{1,1}{1});
                idx_al=find(strcmpi(list_params,'--'));
                obj.algo=algo_alt(idx_al);
                obj.default_params_h=uicontrol(obj.container,gui_fmt.popumenuStyle,'String',list_params,'Value',idx_al,...
                    'Position', pos{1,1}{1}+[gui_fmt.txt_w+gui_fmt.x_sep 0 0 0],...
                    'callback',@load_params_fcn,'Tag',obj.algo.Name);
                ir0=1;
            else
                ir0=0;
            end 
            str_disp=obj.algo.Input_params.to_string();
            ip=0;
            %ic_add=0;
            for ui=1:numel(param_names)
                addprop(obj,param_names{ui});
                if isempty(results.input_struct_h) || ~isfield(results.input_struct_h,param_names{ui})
                    ip=ip+1;
                    ic=rem(ip,nb_c);
                    ic(ic==0)=nb_c;
                    ir=ceil(ip/nb_c)+ir0;                   
                    switch params_class{ui}
                        case 'cell'
                            p_tmp=pos{ir,ic}{1}+[0 0 pos{ir,ic}{2}(3) 0];
                            uicontrol(obj.container,gui_fmt.txtStyle,'string',str_disp{ui},'pos',p_tmp,'tooltipstring',obj.algo.Input_params(ui).Tooltipstring);
                            if ic<nb_c
                                p_tmp=pos{ir,ic+1}{1}+[0 0 pos{ir,ic+1}{2}(3) 0];
                            else
                                p_tmp=pos{ir,ic}{1}+[0 0 pos{ir,ic}{2}(3) 0];
                            end
                            %p_tmp=pos{ir,ic}{1}+[0 0 pos{ir,ic}{2}(3) 0];
                            obj.(param_names{ui})=uicontrol(obj.container,gui_fmt.popumenuStyle,'Value',find(strcmpi(obj.algo.Input_params(ui).Value,obj.algo.Input_params(ui).Value_range)),...
                                'String',obj.algo.Input_params(ui).Value_range,'Position',p_tmp,...
                                'callback',@update_algo_input_param_fcn,...
                                'tooltipstring',obj.algo.Input_params(ui).Tooltipstring,'Tag',param_names{ui});
                            ip=ip+1;
                        case {'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                            if ~isempty(str_disp{ui})
                                uicontrol(obj.container,gui_fmt.txtStyle,'string',str_disp{ui},'pos',pos{ir,ic}{1},'tooltipstring',obj.algo.Input_params(ui).Tooltipstring);
                            end
                            obj.(param_names{ui}) = uicontrol(obj.container,gui_fmt.edtStyle,'pos',pos{ir,ic}{2},...
                                'string',num2str(obj.algo.Input_params(ui).Value,obj.algo.Input_params(ui).Precision),...
                                'callback',@update_algo_input_param_fcn,...
                                'tooltipstring',obj.algo.Input_params(ui).Tooltipstring,'Tag',param_names{ui});
                        case 'logical'

                            p_tmp=pos{ir,ic}{1};

                            obj.(param_names{ui})=uicontrol(obj.container,gui_fmt.chckboxStyle,'Value',obj.algo.Input_params(ui).Value,...
                                'String',str_disp{ui},'Position',p_tmp,...
                                'callback',@update_algo_input_param_fcn,...
                                'tooltipstring',obj.algo.Input_params(ui).Tooltipstring,'Tag',param_names{ui});
                            if ~(numel(param_names)>ui&&strcmpi(params_class{ui+1},'logical'))
                                ip = ip-1;
                            end

                    end
                else
                    obj.(param_names{ui})=results.input_struct_h.(param_names{ui});
                    set(obj.(param_names{ui}),'tooltipstring',obj.algo.Input_params(ui).Tooltipstring,'Tag',param_names{ui},'callback',@update_algo_input_param_fcn);
                    switch class(obj.algo.Input_params(ui).Value)
                        case {'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                            set(obj.(param_names{ui}),'string',num2str(obj.algo.Input_params(ui).Value,obj.algo.Input_params(ui).Precision));
                        case 'logical'
                            set(obj.(param_names{ui}),'value',obj.algo.Input_params(ui).Value);
                    end
                end
            end
            
            uicontrol(obj.container,gui_fmt.pushbtnStyle,'String','Apply','pos',p_button+[1*gui_fmt.button_w 0 0 0],'callback',results.apply_cback_fcn,'Tag',obj.algo.Name,'TooltipString',obj.algo.get_algo_descr_and_params());
            uicontrol(obj.container,gui_fmt.pushbtnStyle,'String','Save','pos',p_button+[2*gui_fmt.button_w 0 0 0],'callback',results.save_cback_fcn,'Tag',obj.algo.Name);
            
            if ~isempty(results.save_as_cback_fcn)
                uicontrol(obj.container,gui_fmt.pushbtnStyle,'String','Save as','pos',p_button+[3*gui_fmt.button_w 0 0 0],'callback',results.save_as_cback_fcn,'Tag',obj.algo.Name);
                uicontrol(obj.container,gui_fmt.pushbtnStyle,'String','Delete','pos',p_button+[4*gui_fmt.button_w 0 0 0],'callback',results.delete_cback_fcn,'Tag',obj.algo.Name);
            end
            
            function load_params_fcn(src,evt)
                [~,~,xml_file]=get_config_files(src.Tag);
                [~,algo_alt,names]=read_config_algo_xml(xml_file{1});
                
                idx_algo_xml=find(strcmpi(names,src.String{src.Value}));
                
                if ~isempty(idx_algo_xml)
                    update_algo_panel(obj,algo_alt(idx_algo_xml))
                end

            end
            
            
            function update_algo_input_param_fcn(src,evt)
                algo_param_obj = get_algo_param(obj.algo,src.Tag);
                
                if isempty(algo_param_obj)
                    return;
                end
                
                switch src.Style
                    case 'edit'
                        check_fmt_box(src,[],algo_param_obj.Value_range(1),algo_param_obj.Value_range(2),algo_param_obj.Value,algo_param_obj.Precision);
                        value = str2double(src.String);
                    case 'checkbox'
                        value = src.Value>0;
                    case 'popupmenu'
                        value = src.String{src.Value};
                    otherwise
                        return;
                end
                
                obj.algo.set_input_param_value(src.Tag,value);
                
            end
        end
        
        function [algo_panel,idx_panel]=get_algo_panel(obj,name)
            algo_names=obj.list_algos();
            idx_panel=find(ismember(algo_names,name));
            algo_panel=obj(ismember(algo_names,name));
            
        end
        
        function algo_names=list_algos(obj)
            algo_names=cell(1,numel(obj));
            for ui =1:numel(obj)
                algo_names{ui}=obj(ui).algo.Name;
            end
        end
        
        function update_algo_panel(obj,algo)           
            if strcmpi(algo.Name,obj.algo.Name)
                param_names=obj.algo.Input_params.get_name();               
                for ui=1:numel(param_names)   
                    switch obj.(param_names{ui}).Style
                        case 'edit'
                            switch class(obj.algo.Input_params(ui).Default_value)
                                case {'single' 'double' 'int8' 'int16' 'int32' 'int64' 'uint8' 'uint16' 'uint32' 'uint64'}
                                    obj.(param_names{ui}).String = num2str(algo.Input_params(ui).Value,obj.algo.Input_params(ui).Precision);
                                case 'logical'
                                    obj.(param_names{ui}).Value=algo.Input_params(ui).Value;
                                case 'char'
                                    obj.(param_names{ui}).Value=algo.Input_params(ui).Value;
                            end
                        case 'checkbox'
                                obj.(param_names{ui}).Value=algo.Input_params(ui).Value>0;
                        case 'popupmenu'
                            obj.(param_names{ui}).String=algo.Input_params(ui).Value_range;
                            idx = find(strcmpi(algo.Input_params(ui).Value,algo.Input_params(ui).Value_range));
                            if ~isempty(idx)
                                obj.(param_names{ui}).Value=idx;
                            end
                    end
                end  
               
                obj.algo=algo;
            else
               print_errors_and_warnings([],'warning',sprintf('Trying to update %s algo panel with %s algo object',obj.algo.Name,algo.Name)) 
            end

        end
        
        function reset_default_params_h(obj)
            if ~isempty(obj.default_params_h)
                id=find(strcmpi(obj.default_params_h.String,'--'));
                if ~isempty(id)
                    obj.default_params_h.Value=id;
                end
            end
        end
        
        function delete(obj)
            
            if ~isdeployed
                c = class(obj);
                delete(obj.container);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        
    end
    
end




