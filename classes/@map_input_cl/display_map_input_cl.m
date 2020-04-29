function hfigs=display_map_input_cl(obj_tot,varargin)
p = inputParser;

addRequired(p,'obj_tot',@(x) isa(x,'map_input_cl'));
addParameter(p,'hfig',[],@(h) isempty(h)|isa(h,'matlab.ui.Figure'));
addParameter(p,'main_figure',[],@(h) isempty(h)|isa(h,'matlab.ui.Figure'));
addParameter(p,'echomaps',{},@(h) iscell(h));
addParameter(p,'field','SliceAbscf',@ischar);
addParameter(p,'oneMap',0,@isnumeric);
addParameter(p,'coloredCircle','Proportional',@ischar);
addParameter(p,'LatLim',[],@isnumeric);
addParameter(p,'LongLim',[],@isnumeric);
addParameter(p,'Colormap',[],@(x) isnumeric(x)||ischar(x));

parse(p,obj_tot,varargin{:});
hfig=p.Results.hfig;

if isempty(hfig)
    new_figs=1;
else
    hfig(~isvalid(hfig))=[];
    if isempty(hfig)
        new_figs=1;
    else
        new_figs=0;
        hfigs=hfig;
    end
end

main_figure=p.Results.main_figure;
field=p.Results.field;
uid=generate_Unique_ID(numel(obj_tot));

for ui=1:numel(obj_tot)
    obj=obj_tot(ui);

    surv_name=unique(obj.Title);
    
    fig_name=sprintf('%s',strjoin(surv_name, 'and'));
    
    
    if new_figs
        hfigs(ui)=new_echo_figure(main_figure,'Name',fig_name,'Tag',sprintf('nav_%s',uid{ui}),'Toolbar','esp3','MenuBar','esp3');
        hfig=hfigs(ui);
    end
    
    if ~isempty(p.Results.Colormap)
        colormap(hfig,p.Results.Colormap);
    end
    
    col_snap={'k'};
    
    LongLim=[nan nan];
    LatLim=[nan nan];
    
    
    if ~strcmp(field,'Tag')
        [~,~,survey_name_num]=unique(obj.SurveyName);
        snap=unique([obj.Snapshot(:)';survey_name_num(:)']','rows');
    else
        [tag,~]=unique(obj.Regions.Tag);
        snap=ones(length(tag),2);
    end
    
    LongLim(1)=nanmin(LongLim(1),obj.LongLim(1));
    LongLim(2)=nanmax(LongLim(2),obj.LongLim(2));
    LatLim(1)=nanmin(LatLim(1),obj.LatLim(1));
    LatLim(2)=nanmax(LatLim(2),obj.LatLim(2));
    
    [LatLim,LongLim]=ext_lat_lon_lim_v2(LatLim,LongLim,0.1);
    
    if p.Results.oneMap>0
        snap=[1 1];
    end
    nb_snap=size(snap,1);
    
    nb_row=ceil(nb_snap/3);
    nb_col=nanmin(nb_snap,3);
    
    
    n_ax=gobjects(nb_snap,1);
    
    for usnap=1:nb_snap
        if nb_snap>1
            id_c=rem(usnap,nb_col);
            id_c(id_c==0)=nb_col;
            id_r=nb_row-floor((usnap-1)/nb_col);
            pos=[(id_c-1)/nb_col (id_r-1)/nb_row 1/nb_col 1/nb_row];
        else
            pos=[0 0 1 1];
        end
        n_ax(usnap)=geoaxes('Parent',hfig,...
            'OuterPosition',pos,'basemap',obj.Basemap); 
    end
    format_geoaxes(n_ax);
    
    if ~strcmp(field,'Tag')
        
        for usnap=1:nb_snap
            if p.Results.oneMap==0
                idx_snap=find(obj.Snapshot==snap(usnap,1)&survey_name_num(:)'==snap(usnap,2));
                
                if isempty(idx_snap)
                    continue;
                end
                
            else
                idx_snap=1:length(obj.Snapshot);
            end
            vals=obj.(field)(idx_snap);
            
            val_max=nanmax(cellfun(@nanmax,vals(~cellfun(@isempty,vals))));
            
            switch lower(obj.PlotType)
                case {'log10' 'db'}
                    c_max=obj.Rmax*(log10(1+val_max/obj.ValMax));
                    
                case {'sqrt' 'square root'}
                    c_max=obj.Rmax*sqrt(val_max/obj.ValMax);
                    
                case 'linear'
                    c_max=obj.Rmax*(val_max/obj.ValMax);
                    
            end
            
            
            for uui=1:length(idx_snap)
                
                
                if ~isempty(obj.SliceLong{idx_snap(uui)})
                    
                    if ~strcmp(field,'Tag')
                        switch lower(obj.PlotType)
                            case {'log10' 'db'}
                                ring_size=zeros(size(obj.(field){idx_snap(uui)}));
                                ring_size(obj.(field){idx_snap(uui)}>0)=obj.Rmax*(log10(1+obj.(field){idx_snap(uui)}(obj.(field){idx_snap(uui)}>0)/obj.ValMax));
                                
                            case {'sqrt' 'square root'}
                                ring_size=obj.Rmax*sqrt(obj.(field){idx_snap(uui)}/obj.ValMax);
                                
                            case 'linear'
                                ring_size=obj.Rmax*(obj.(field){idx_snap(uui)}/obj.ValMax);
                                
                        end
                        
                        idx_rings=find(ring_size>0);
                        
                        %'color',col_snap{rem(usnap,length(col_snap))+1}
                        switch p.Results.coloredCircle
                            
                            case 'Red'
                                C=[0.5 0 0];
                            case 'Blue'
                                C=[0 0 0.5];
                            case 'Black'
                                C=[0 0 0];
                            case 'Green'
                                C=[0 0.5 0];
                            case 'Yellow'
                                C=[ 0.8 0.8 0];
                            case 'White'
                                C=[1 1 1];
                            otherwise
                                C=ring_size(idx_rings)/c_max;
                                
                        end
                        s_obj=geoscatter(n_ax(usnap),obj.SliceLat{idx_snap(uui)}(idx_rings),obj.SliceLong{idx_snap(uui)}(idx_rings),pi*ring_size(idx_rings).^2,C,'filled');
                        set(s_obj,'MarkerFaceAlpha',0.6,'MarkerEdgeAlpha',0.6);
                        set(s_obj,'ButtonDownFcn',{@disp_line_name_callback,hfig,idx_snap(uui)});
                    end
                    if isempty(obj.Long{idx_snap(uui)})
                        geoplot(n_ax(usnap),obj.SliceLat{idx_snap(uui)}(1),obj.SliceLong{idx_snap(uui)}(1),'Marker','o','Markersize',4,'Color',[0 0.5 0],'tag','start');
                    end
                    gobj=geoplot(n_ax(usnap),obj.SliceLat{idx_snap(uui)},obj.SliceLong{idx_snap(uui)},'color','k','Tag','Nav');
                    set(gobj,'ButtonDownFcn',{@disp_line_name_callback,hfig,idx_snap(uui)});
                    
                    if~isempty(main_figure)
                        create_context_menu_track(main_figure,hfig,gobj);
                    end
                    
                    ipt.enterFcn =  @(figHandle, currentPoint)...
                        set(figHandle, 'Pointer', 'hand');
                    ipt.exitFcn =  @(figHandle, currentPoint)...
                        set(figHandle, 'Pointer', 'arrow');
                    ipt.traverseFcn = [];
                    iptSetPointerBehavior(gobj,ipt);
                    
                    if~isempty(main_figure)
                        create_context_menu_track(main_figure,hfig,gobj);
                    end
                    
                    
                    
                end
                
                if ~isempty(obj.Long{idx_snap(uui)})
                    gobj=geoplot(n_ax(usnap),obj.Lat{idx_snap(uui)},obj.Long{idx_snap(uui)},'color','k','linewidth',1,'Tag','Nav');
                    set(gobj,'ButtonDownFcn',{@disp_line_name_callback,hfig,idx_snap(uui)});
                    geoplot(n_ax(usnap),obj.Lat{idx_snap(uui)}(1),obj.Long{idx_snap(uui)}(1),'Marker','o','Markersize',4,'Color',[0 0.5 0],'tag','start');
                    if~isempty(main_figure)
                        create_context_menu_track(main_figure,hfig,gobj);
                    end
                    if ~isempty(obj.StationCode{idx_snap(uui)})
                        text(nanmean(obj.Lat{idx_snap(uui)}),nanmean(obj.Long{idx_snap(uui)}),obj.StationCode{idx_snap(uui)},'parent',n_ax(usnap),'color','r');
                    end
                end
                
                
            end
            if p.Results.oneMap==0
                title(n_ax(usnap),sprintf('%s Snapshot %d',obj.Voyage{idx_snap(1)},snap(usnap,1)),'Interpreter','none');
            else
                
                title(n_ax(usnap),sprintf('%s',obj.Voyage{idx_snap(1)}),'Interpreter','none');
            end
            
        end
        
        
    else
        
        for utag=1:length(tag)
            title(n_ax(utag),sprintf('%s: %s\n',obj.Voyage{1},tag{utag}));
            if strcmp(field,'Tag')
                ireg_tag=find(strcmp(obj.Regions.Tag,tag{utag}));
                if isempty(ireg_tag)
                    continue;
                end
                
                obj.Regions.Stratum(cellfun(@isempty,obj.Regions.Stratum))={' '};
                
                trans_ids=findgroups(obj.Regions.Snapshot(ireg_tag),obj.Regions.Stratum{ireg_tag},obj.Regions.Transect(ireg_tag));
                
                for itrans=1:length(unique_trans)
                    itrans_curr=find(trans_ids==itrans);
                    text(nanmean(obj.Regions.Lat_m(ireg_tag(itrans_curr))),nanmean(obj.Regions.Long_m(ireg_tag(itrans_curr))),tag{utag},'parent',n_ax(utag),'color','r');
                    text(nanmean(obj.Regions.Lat_m(ireg_tag(itrans_curr))),nanmean(obj.Regions.Long_m(ireg_tag(itrans_curr))),sprintf('\n,%.0f',obj.Regions.Transect(ireg_tag(itrans_curr(1)))),'parent',n_ax(utag),'color','b');
                end
            end
            
        end
    end
    
    for iax=1:numel(n_ax)
        if ~isempty(p.Results.LatLim)
            geolimits(n_ax(iax),p.Results.LatLim,p.Results.LongLim);
        else
            geolimits(n_ax(iax),LatLim,LongLim);
        end
    end
    
    if obj.Depth_Contour>0
        for usnap=1:nb_snap
            try
                [map_tab_comp.contour_plots,map_tab_comp.contour_texts]=plot_cont_from_etopo1(n_ax(usnap),obj.Depth_Contour);
            catch
                disp_perso(main_figure,'Cannot find Etopo1 data...')
            end
        end
    end
    %linkaxes(n_ax,'x');
    
    if ~isempty(p.Results.echomaps)
        for usnap=1:nb_snap
            geoplot_shp(n_ax(usnap),p.Results.echomaps,[]);
        end
    end
    
    if ~isempty(main_figure)
        set(hfig,'WindowButtonDownFcn',{@copy_axes_callback,main_figure});
    else
        set(hfig,'WindowButtonDownFcn',{@copy_axes_callback});
    end
    
    
    
    Map_info.LongLim=LongLim;
    Map_info.LatLim=LatLim;
    setappdata(hfig,'Idx_select',[]);
    set(n_ax,'UserData',Map_info);
    setappdata(hfig,'Map_input',obj);
    %linkprop(n_ax,{'LongitudeLimits','LatitudeLimits'});
    
end

end

function disp_line_name_callback(src,evt,hfig,idx_obj)

ax=get(src,'Parent');
idx_selected=getappdata(hfig,'Idx_select');
obj=getappdata(hfig,'Map_input');

cp=evt.IntersectionPoint;
x = cp(1,1);
y=cp(1,2);

switch hfig.SelectionType
    case 'normal'
        str=obj.get_str(idx_obj);
        idx_selected=idx_obj;
        u = findobj(ax,'Tag','name');
        delete(u);
        
        text(x,y,str{1},'Interpreter','None','Tag','name','parent',ax,'EdgeColor','k','BackgroundColor','w');
        
        %dim = [0.1 0.1 0.2 0.3];
        
        %annotation('textbox',dim,'String',str{1},'FitBoxToText','on','Interpreter','None','Tag','name');
        
        lines = findobj(ax,'Type','Line','Tag','Nav');
        for il=1:length(lines)
            if lines(il)==src
                set(lines(il),'color','r');
            else
                set(lines(il),'color','k');
            end
        end
        
    case 'alt'
        lines = findobj(ax,'Type','Line','Tag','Nav');
        idx_selected=unique([idx_selected idx_obj],'stable');
        for il=1:length(lines)
            if lines(il)==src
                set(lines(il),'color','r');
            end
        end
        
end
setappdata(hfig,'Idx_select',idx_selected);


end





