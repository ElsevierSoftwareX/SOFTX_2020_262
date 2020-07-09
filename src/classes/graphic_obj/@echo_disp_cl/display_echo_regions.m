function reg_plot_tot = display_echo_regions(echo_obj,trans_obj,varargin)

curr_disp_default=curr_state_disp_cl();

p = inputParser;
addRequired(p,'echo_obj',@(x) isa(x,'echo_disp_cl'));
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'text_size',8,@isnumeric);
addParameter(p,'curr_disp',curr_disp_default,@(x) isa(x,'curr_state_disp_cl'));

parse(p,echo_obj,trans_obj,varargin{:});

curr_disp = p.Results.curr_disp;

[ac_data_col,ac_bad_data_col,in_data_col,in_bad_data_col,txt_col]=set_region_colors(curr_disp.Cmap);
reg_plot_tot =[];

switch curr_disp.DispReg
    case 'off'
        alpha_in=0;
    case 'on'
        alpha_in=0.4;
end

main_axes=echo_obj.main_ax;

di=1/2;

active_regs=trans_obj.find_regions_Unique_ID(curr_disp.Active_reg_ID);

reg_h=findobj(main_axes,{'tag','region','-or','tag','region_text'});

if~isempty(reg_h)
    id_disp=get(reg_h,'UserData');
    id_reg=trans_obj.get_reg_Unique_IDs();
    id_rem = setdiff(id_disp,id_reg);
    
    if~isempty(id_rem)
        echo_obj.clear_echo_regions(id_rem)
    end
    
end

nb_reg=numel(trans_obj.Regions);
reg_text_obj=findobj(main_axes,{'tag','region_text'},'-depth',1);

for i=1:nb_reg
    try
        reg_curr=trans_obj.Regions(i);
        
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
        
        switch echo_obj.echo_usrdata.geometry_y
            case'samples'
                %                     reg_trans_depth=zeros(size(reg_curr.Idx_pings));
                %                     dr=1;
                poly.Vertices(:,1)=poly.Vertices(:,1)+1/2;
                poly.Vertices(:,2)=poly.Vertices(:,2)+di;
                
                %r_text=nanmean(reg_curr.Idx_r);
            case 'depth'
                
                if curr_disp.DispSecFreqsWithOffset>0
                    reg_trans_depth=trans_obj.get_transducer_depth(reg_curr.Idx_pings);
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
                
                r=trans_obj.get_transceiver_range();
                t_angle=trans_obj.get_transducer_pointing_angle();
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
        
        id = 1;
        for uipo=idx_sort(1:nb_draw)'
            id=id+1;
            reg_plot(id)=text(nanmean(sub_reg_poly(uipo).Vertices(:,1)),nanmean(sub_reg_poly(uipo).Vertices(:,2)),reg_curr.disp_str(),'FontWeight','Normal','Fontsize',...
                p.Results.text_size,'Tag','region_text','color',txt_col,'parent',main_axes,'UserData',reg_curr.Unique_ID,'Clipping', 'on','interpreter','none');
        end
        
        reg_plot_tot = [reg_plot_tot reg_plot];
        
    catch err
        warning('Error display region ID %.0f',reg_curr.ID);
        print_errors_and_warnings(1,'error',err);
    end
end