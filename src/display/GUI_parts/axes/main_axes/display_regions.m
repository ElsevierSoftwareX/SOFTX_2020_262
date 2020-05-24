function display_regions(main_figure,varargin)

% profile on;

layer=get_current_layer();

axes_panel_comp=getappdata(main_figure,'Axes_panel');

curr_disp=get_esp3_prop('curr_disp');


[ac_data_col,ac_bad_data_col,in_data_col,in_bad_data_col,txt_col]=set_region_colors(curr_disp.Cmap);

if ~isempty(varargin)
    if ischar(varargin{1})
        switch varargin{1}
            case 'both'
                main_or_mini={'main' 'mini' curr_disp.ChannelID};
            case 'mini'
                main_or_mini={'mini'};
            case 'main'
                main_or_mini={'main' curr_disp.ChannelID};
            case 'all'
                main_or_mini=union({'main' 'mini'},layer.ChannelID);
        end
    elseif iscell(varargin{1})
        main_or_mini=varargin{1};
    end
else
    main_or_mini=union({'main' 'mini'},layer.ChannelID);
end

[echo_im_tot,main_axes_tot,~,trans_obj,text_size,cids]=get_axis_from_cids(main_figure,main_or_mini);

for iax=1:length(main_axes_tot)
    trans=trans_obj{iax};
    
    switch curr_disp.DispReg
        case 'off'
            alpha_in=0;
        case 'on'
            alpha_in=0.4;
    end
    
    main_axes=main_axes_tot(iax);
    echo_in=echo_im_tot(iax);
    
    
    di=1/2;
    
    
    active_regs=trans.find_regions_Unique_ID(curr_disp.Active_reg_ID);
    
    reg_h=findobj(main_axes,{'tag','region','-or','tag','region_text','-or','tag','region_cont'});
    
    if~isempty(reg_h)
        id_disp=get(reg_h,'UserData');
        id_reg=trans.get_reg_Unique_IDs();
        id_rem = setdiff(id_disp,id_reg);
        
        if~isempty(id_rem)
            clear_regions(main_figure,id_rem,union({'main' 'mini'}, cids{iax}));
        end
    end
    
    nb_reg=numel(trans.Regions);
    %reg_graph_obj=findobj(main_axes,{'tag','region','-or','tag','region_cont'},'-depth',1);
    reg_text_obj=findobj(main_axes,{'tag','region_text'},'-depth',1);
    
    for i=1:nb_reg
        try
            reg_curr=trans.Regions(i);
            
            if ~isempty(reg_text_obj)
                id_text=findobj(reg_text_obj,'UserData',reg_curr.Unique_ID,'-depth',0);
                if ~isempty(id_text)
                    set(id_text,'String',reg_curr.disp_str());
                    continue;
                end
                
            end
            
            if any(i==active_regs)
                
                switch lower(reg_curr.Type)
                    case 'data'
                        col=ac_data_col;
                    case 'bad data'
                        col=ac_bad_data_col;
                end
            else
                
                switch lower(reg_curr.Type)
                    case 'data'
                        col=in_data_col;
                    case 'bad data'
                        col=in_bad_data_col;
                end
            end
            
            poly=reg_curr.Poly;
            
            switch main_axes.UserData.geometry_y
                case'samples'
                    %                     reg_trans_depth=zeros(size(reg_curr.Idx_pings));
                    %                     dr=1;
                    poly.Vertices(:,1)=poly.Vertices(:,1)+1/2;                 
                    poly.Vertices(:,2)=poly.Vertices(:,2)+di;    
                    
                    %r_text=nanmean(reg_curr.Idx_r);                   
                case 'depth'
                    
                    if curr_disp.DispSecFreqsWithOffset>0
                        reg_trans_depth=trans.get_transducer_depth(reg_curr.Idx_pings);
                    else
                        reg_trans_depth=zeros(1,numel(reg_curr.Idx_pings));
                    end
                    
                    if numel(unique(reg_trans_depth))==1
                        reg_trans_depth=unique(reg_trans_depth);
                    end
                    

                    
                    if any(reg_trans_depth~=0)
                        if numel(reg_trans_depth)>1&&~strcmp(reg_curr.Shape,'Polygon')
                            diff_vert=diff(poly.Vertices(:,1));
                            temp_x_vert=arrayfun(@(x,z) x+sign(z)*(0:abs(z))',poly.Vertices(1:end-1,1),diff_vert,'un',0);
                            %id_rem=isnan(diff_vert);
                            idx_d=find(diff_vert==0);
                            for idi=idx_d(:)'
                                temp_x_vert{idi}=[ temp_x_vert{idi} ;temp_x_vert{idi}];
                            end
                            %temp_x_vert(id_rem)=[];
                            diff_vert(diff_vert==0)=1;
                            temp_y_vert=arrayfun(@(x,y,z) linspace(x,y,z)',poly.Vertices(1:end-1,2),poly.Vertices(2:end,2),abs(diff_vert)+1,'un',0);
                            temp_x_vert=cell2mat(temp_x_vert);
                            temp_y_vert=cell2mat(temp_y_vert);
                            idx_nan=isnan(temp_x_vert)|isnan(temp_y_vert);
                            temp_x_vert(idx_nan)=nan;
                            temp_y_vert(idx_nan)=nan;
                            poly=polyshape([temp_x_vert temp_y_vert],'Simplify',false);
                        end
                    end
                    
                    r=trans.get_transceiver_range();
                    t_angle=trans.get_transducer_pointing_angle();
                    new_vert=nan(size(poly.Vertices(:,2)));
                    idx=~isnan(poly.Vertices(:,2));
                    idx_r=round(poly.Vertices(idx,2));
                    idx_r(idx_r==0)=1;
                    new_vert(~isnan(poly.Vertices(:,2)))=r(idx_r)*sin(t_angle);
                    poly.Vertices(:,2)=new_vert;
                    
                    poly.Vertices(:,1)=poly.Vertices(:,1)+1/2;
                    
                    if numel(reg_trans_depth)>1
                        [~,idx]=nanmin(abs(poly.Vertices(:,1)-reg_curr.Idx_pings),[],2);
                        poly.Vertices(:,2)=poly.Vertices(:,2)+reg_trans_depth(idx)';
                    else
                        poly.Vertices(:,2)=poly.Vertices(:,2)+reg_trans_depth;
                    end
                    
                    %r_text=nanmean(poly.Vertices(:,2));
            end
            
            
            sub_reg_poly=poly.regions;
            s_reg=arrayfun(@(x) size(x.Vertices,1),sub_reg_poly);
            
            [s_reg_s,idx_sort]=sort(s_reg,'descend');
            
            switch lower(reg_curr.Shape)
                case 'rectangular'
                    nb_draw=1;
                otherwise
                    nb_draw=nanmax(nansum(s_reg_s>=20),1);
                    
            end
            
            reg_plot=gobjects(1,nb_draw+1);
            
            reg_plot(1)=plot(main_axes,poly, 'FaceColor',col,...
                'parent',main_axes,'FaceAlpha',alpha_in,...
                'EdgeColor',col,...
                'LineWidth',0.7,...
                'tag','region',...
                'UserData',reg_curr.Unique_ID);
            
            id=1;
            for uipo=idx_sort(1:nb_draw)'                
                id=id+1;
                reg_plot(id)=text(nanmean(sub_reg_poly(uipo).Vertices(:,1)),nanmean(sub_reg_poly(uipo).Vertices(:,2)),reg_curr.disp_str(),'FontWeight','Normal','Fontsize',...
                text_size(iax),'Tag','region_text','color',txt_col,'parent',main_axes,'UserData',reg_curr.Unique_ID,'Clipping', 'on');
            end
            
            for ii=1:length(reg_plot)
                iptaddcallback(reg_plot(ii),'ButtonDownFcn',{@set_active_reg,reg_curr.Unique_ID,main_figure});
                iptaddcallback(reg_plot(ii),'ButtonDownFcn',{@move_reg_callback,reg_curr.Unique_ID,main_figure});
            end
            
            if main_axes==axes_panel_comp.main_axes
                create_region_context_menu(reg_plot,main_figure,reg_curr.Unique_ID);
                ipt.enterFcn =  @(figHandle, currentPoint)...
                    set(figHandle, 'Pointer', 'hand');
                ipt.exitFcn =  [];
                ipt.traverseFcn = [];
                iptSetPointerBehavior(reg_plot,ipt);
            end
        catch err
            warning('Error display region ID %.0f',reg_curr.ID);
            print_errors_and_warnings(1,'error',err);
        end
    end

    order_stacks_fig(main_figure,curr_disp)
    
end



