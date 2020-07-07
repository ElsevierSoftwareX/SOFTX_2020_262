function h_fig = display_region_3D(reg_obj,trans_obj,data_struct,varargin)

%% input variable management

p = inputParser;

% default values
field_def='sp';

[cax_d,~,~]=init_cax(field_def);
addRequired(p,'reg_obj',@(obj) isa(obj,'region_cl'));
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'data_struct',@(x) isempty(x)|isstruct(x));
addParameter(p,'Name',reg_obj.print(),@ischar);
addParameter(p,'Cax',cax_d,@isnumeric);
addParameter(p,'Cmap','ek60',@ischar);
addParameter(p,'alphadata',[],@isnumeric);
addParameter(p,'field',field_def,@ischar);
addParameter(p,'trackedOnly',0,@isnumeric);
addParameter(p,'thr',nan,@isnumeric);
addParameter(p,'main_figure',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'parent',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'load_bar_comp',[]);

parse(p,reg_obj,trans_obj,data_struct,varargin{:});

curr_disp=get_esp3_prop('curr_disp');

field=p.Results.field;

if isempty(p.Results.data_struct)    
    [data_struct_new,no_nav,zone] = reg_obj.get_region_3D_echoes(trans_obj,varargin{:});
else
    data_struct_new=p.Results.data_struct;
    no_nav=1;
end
if isempty(data_struct_new)
    return;
end

tag=sprintf('3DDisplay%d%s',trans_obj.Config.Frequency,field);

if ~isempty(p.Results.main_figure)
    hfigs=getappdata(p.Results.main_figure,'ExternalFigures');
    if ~isempty(hfigs)
        hfigs(~isvalid(hfigs))=[];
        idx_tag=find(strcmpi({hfigs(:).Tag},tag));
    else
        idx_tag=[]; 
    end
else
    idx_tag=[];
end

if ~isempty(idx_tag)
    h_fig=hfigs(idx_tag(1));
    data_struct=getappdata(h_fig,'data_struct');
    plot_struct=getappdata(h_fig,'plot_struct');
else
    h_fig=new_echo_figure(p.Results.main_figure,'Name','3D Display','Tag',tag,...
        'Units','normalized','Position',[0.1 0.2 0.4 0.6],'Group','Regions','Windowstyle','Docked','Toolbar','esp3','MenuBar','esp3');

    %% color bounds and cmap
    if ~isempty(curr_disp)
        cax_list=addlistener(curr_disp,'Cax','PostSet',@(src,envdata)listenCaxReg(src,envdata));
        cmap_list=addlistener(curr_disp,'Cmap','PostSet',@(src,envdata)listenCmapReg(src,envdata));
    end
    
end

x_lab='Meters';
y_lab='Meters';

if ~isempty(curr_disp)
    cax=curr_disp.getCaxField(field);
    cmap_name=curr_disp.Cmap;
else
    cax=p.Results.Cax;
    cmap_name=p.Results.Cmap;
    cmap_list=[];
    cax_list=[];
end

switch field
    case 'singletarget'
         size_data=10;
    otherwise
        size_data=5;
end

ax=findobj(h_fig,'Tag','3DAxes');
if isempty(ax)
    [cmap,col_ax,~,col_grid,~,~,~]=init_cmap(cmap_name);
    ax=axes('Parent',h_fig,'Units','Normalized','position',[0.05 0.05 0.9 0.9],'xaxislocation','top','nextplot','add','box','on','DeleteFcn',@delete_axes,'Tag','3DAxes','BoxStyle','full','Color',col_ax,'GridColor',col_grid);
    plot_struct.echoes=scatter3(ax,nan,nan,nan,size_data,nan,'filled','MarkerFaceAlpha',0.8,'MarkerEdgeAlpha',0.8);
    xlabel(ax,x_lab,'fontsize',14)
    ylabel(ax,y_lab,'fontsize',14)
    zlabel(ax,'Depth(m)')
    set(ax,'fontsize',14);
    colormap(ax,cmap);
    grid(ax,'on');
    axis(ax,'square');
    box(ax,'on');
    view(ax,3)
    caxis(ax,cax);
    cb=colorbar(ax,'PickableParts','none');
    cb.UIContextMenu=[];
    %axis(ax,'ij');
   %axis(ax,'equal')
    data_struct=data_struct_new;
    plot_struct.vessel=scatter3(ax,nan,nan,nan,8,'k','filled');
    plot_struct.bottom=scatter3(ax,nan,nan,nan,8,'k');
    plot_struct.beam_maj_ax=plot3(ax,nan,nan,nan,'Linestyle','--','Color',[0.2 0.2 0.2]);
    plot_struct.beam_min_ax=plot3(ax,nan,nan,nan,'Linestyle','--','Color',[0.2 0.2 0.2]);
    plot_struct.beam_circle=plot3(ax,nan,nan,nan,'Linestyle','--','Color',[0.2 0.2 0.2]);
else
    fields=fieldnames(data_struct_new);
    for ifi=1:numel(fields)
        data_struct.(fields{ifi})= [data_struct.(fields{ifi});data_struct_new.(fields{ifi})];
    end

end

setappdata(h_fig,'data_struct',data_struct);
setappdata(h_fig,'plot_struct',plot_struct);

if no_nav
    dar=ax.DataAspectRatio;
    dar=[dar(2) dar(2) dar(3)];
    ax.DataAspectRatioMode='Manual';
    ax.DataAspectRatio=dar;
    set(ax,'xlim',[nanmin([data_struct.X_t;data_struct.x_vessel]) nanmax([data_struct.X_t;data_struct.x_vessel])],'xlimmode','manual');
    set(ax,'ylim',[nanmin([data_struct.Y_t;data_struct.y_vessel]) nanmax([data_struct.Y_t;data_struct.y_vessel])],'ylimmode','manual');
end

disp_all=true;
%disp_all=false;
if disp_all
    update_ax(h_fig,cax,[],field);
else
    dt=gradient(data_struct.time(:)')*24*60*60;
    it=0;
    nb_pings_disp=10;
    disp_speed=60;
    for i=data_struct.ping_num_vessel(:)'
        it=it+1;
        update_ax(h_fig,cax,i:nanmin((i+nb_pings_disp-1),data_struct.ping_num_vessel(end)),field);
        pause(dt(it)/disp_speed);
    end
end
    function delete_axes(src,~)
        if ~isdeployed
            disp('delete_axes reg listeners')
        end
        delete(cmap_list) ;
        delete(cax_list) ;
        delete(src);
    end

% Listener for colourmap
    function listenCmapReg(src,evt)
        if ~isdeployed
            disp('listenCmapReg')
        end
        [cmap,col_ax,~,col_grid,~,~]=init_cmap(evt.AffectedObject.Cmap);
        try
            if isvalid(ax)
                colormap(ax,cmap);
                set(ax,'GridColor',col_grid,'Color',col_ax);
            end
        catch
            delete(cmap_list);
            delete(cax_list);
        end
    end

% Listener for alpha values to limit data shown
    function listenCaxReg(src,evt)
        cax=evt.AffectedObject.getCaxField(field);
        if ~isdeployed
            disp('listenCaxReg')
        end
        if exist('ax','var')>0       
            if isvalid(ax)
                update_ax(h_fig,cax,[],field);
                caxis(ax,cax);
                %                 alphadata=double(data_disp>cax(1));
                %                 set(reg_plot,'alphadata',alphadata)
            end
        else
            delete(cmap_list);
            delete(cax_list);
        end
    end



end

function update_ax(h_fig,cax,iping,field)
data_struct=getappdata(h_fig,'data_struct');
plot_struct=getappdata(h_fig,'plot_struct');
if isempty(iping)
    Mask_disp=data_struct.mask&data_struct.compensation<10&data_struct.data_disp>cax(1);
else
   Mask_disp =data_struct.mask&data_struct.compensation<10&data_struct.data_disp>cax(1)&ismember(data_struct.ping_num,iping);
end
switch field
    case 'TS'
        TS_tmp=data_struct.data_disp+data_struct.compensation;
    otherwise
        TS_tmp=data_struct.data_disp;
end
TS_tmp=TS_tmp(Mask_disp(:)==1);
Z_tmp=data_struct.depth(Mask_disp(:)==1);
X_t=data_struct.X_t(Mask_disp(:)==1);
Y_t=data_struct.Y_t(Mask_disp(:)==1);

x_vessel=data_struct.x_vessel;
y_vessel=data_struct.y_vessel;

x_ori=nanmean(x_vessel);
y_ori=nanmean(y_vessel);

x_vessel=x_vessel-x_ori;
y_vessel=y_vessel-y_ori;

bottom_x=data_struct.bottom_x-x_ori;
bottom_y=data_struct.bottom_y-y_ori;

set(plot_struct.vessel,'XData',x_vessel,'YData',y_vessel,'ZData',data_struct.surf);
set(plot_struct.bottom,'XData',bottom_x,'YData',bottom_y,'ZData', data_struct.bottom_z);

x=X_t-x_ori;
y=Y_t-y_ori;

set(plot_struct.echoes,'ZData',Z_tmp(:),'XData',x(:),'YData',y(:),'CData',TS_tmp(:));
end
