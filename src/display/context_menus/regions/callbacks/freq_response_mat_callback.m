
function [Sv_f,f_vec]=freq_response_mat_callback(~,~,select_plot,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);

[cal,origin_used]=layer.get_fm_cal(idx_freq);

switch class(select_plot)
    case 'region_cl'
        active_reg=select_plot;
    otherwise
        idx_ping=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        active_reg=region_cl('Idx_ping',idx_ping,'Idx_r',idx_r);
end




show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');

if strcmp(trans_obj.Mode,'FM')
    
    [cmap,col_ax,~,~,~,~,~]=init_cmap(curr_disp.Cmap);
    
    [Sv_f,f_vec,ping_mat,r_mat]=trans_obj.sv_f_from_region(active_reg,'envdata',layer.EnvData,'cal',cal{1},'load_bar_comp',load_bar_comp,'output_size','3D');
    
    pings=ping_mat(1,:);
    range=r_mat(:,1);
    
    Sv_f_per=permute(Sv_f,[1 3 2]);
    
    
    f_val=floor(nanmean(f_vec));
    [~,idx_freq]=nanmin(abs(f_vec-f_val));
    f_val=f_vec(idx_freq);
    
    [X,Y,Z] = meshgrid(f_vec/1e3,pings,range);
    
    %     cax = curr_disp.getCaxField('sv');
    %
    %     cmap_t = zeros(256,3);
    %     for icm = 1:3
    %         cmap_t(129:256,icm) = resample_data_v2(cmap(:,icm),(1:size(cmap,1)),1:128,'Opt','Nearest');
    %     end
    %     render = 'MaximumIntensityProjection';
    %     render = 'VolumeRendering';
    %     amap = [zeros(64,1);zeros(64,1);ones(64,1)/4;ones(64,1)];
    %
    %     V = smooth3(Sv_f_per);
    %     %amap(amap<cax(1)) = nan;
    %     fig=new_echo_figure(main_figure,'Name','Sv(f)','Tag',sprintf('SvRegion2 %.0f',active_reg.Unique_ID),'Toolbar','esp3','MenuBar','esp3');
    %     uv = volshow(V,'parent',fig,'Renderer','VolumeRendering','Colormap',cmap_t,'BackgroundColor',col_ax,'scalefactor',[1 1 0.05],'Alphamap',amap);
    
    fig=new_echo_figure(main_figure,'Name','Sv(f)','Tag',sprintf('SvRegion2 %.0f',active_reg.Unique_ID),'Toolbar','esp3','MenuBar','esp3');
    
    ax=axes(fig,'units','normalized','Position',[0.15 0.2 0.85 0.7]);
    
    
    set(ax,'zdir','reverse','ydir','reverse','box','on');
    grid(ax,'on');
    %set(ax,'GridColor',col_grid);
    hold(ax,'on');
    %hz=surface(ax,squeeze(X(:,:,end)),squeeze(Y(:,:,end)),squeeze(Z(:,:,end)),squeeze(Sv_f_per(:,:,end)));
    hy=surface(ax,squeeze(X(1,:,:)),squeeze(Y(1,:,:)),squeeze(Z(1,:,:)),squeeze(Sv_f_per(1,:,:)));
    %hx0=surface(ax,squeeze(X(:,end,:)),squeeze(Y(:,end,:)),squeeze(Z(:,end,:)),squeeze(Sv_f_per(:,end,:)));
    hx = surface(ax,squeeze(X(:,idx_freq,:)),squeeze(Y(:,idx_freq,:)),squeeze(Z(:,idx_freq,:)),squeeze(Sv_f_per(:,idx_freq,:)));
    
    view(3);
    colormap(ax,cmap);
    caxis(ax,curr_disp.getCaxField('sv'));
    
    set([hx hy],'FaceAlpha', 'interp','FaceColor','interp','EdgeColor','none');
    set(hx,'alphadata',double(hx.CData>ax.CLim(1)));
    %         set(hx0,'alphadata',double(hx0.CData>ax.CLim(1)));
    set(hy,'alphadata',double(hy.CData>ax.CLim(1)));
    %set(hz,'alphadata',double(hz.CData>ax.CLim(1)));
    zlabel(ax,'Range(m)');
    ylabel(ax,sprintf('Ping Number %.0f',pings(1)));
    xlabel(ax,sprintf('%.1fkHz',f_val/1e3));
    set(ax,'Xlim',sort([f_vec(1)/1e3 f_vec(end)/1e3]),'Ylim',[pings(1) pings(end)],'Zlim',[range(1) range(end)]);
    cb=colorbar(ax,'PickableParts','none');
    cb.UIContextMenu=[];
    uicontrol(fig,'Style','slider','Min',nanmin(f_vec)/1e3,'Max',nanmax(f_vec)/1e3,'Value',f_val/1e3,'SliderStep',[0.01 0.1],...
        'units','normalized','Position',[0.2 0.05 0.6 0.02],'Callback',{@change_freq_cback_2,Sv_f_per,f_vec,X,hx,ax,'f'});
    grid(ax,'on');
    uicontrol(fig,'Style','slider','Min',pings(1),'Max',pings(end),'Value',pings(end),'SliderStep',[0.01 0.1],...
        'units','normalized','Position',[0.05 0.1 0.01 0.4],'Callback',{@change_freq_cback_2,Sv_f_per,pings,Y,hy,ax,'p'});
    grid(ax,'on');
    rotate3d(ax,'on');
    

end
hide_status_bar(main_figure);

end


function change_freq_cback_2(src,~,Sv_f_per,f_vec,X,hx,ax,type)

switch type
    case 'f'
        f_val=get(src,'value')*1e3;
        [~,idx_freq]=nanmin(abs(f_vec-f_val));
        
        set(hx,'Cdata',squeeze(Sv_f_per(:,idx_freq,:)),'XData',squeeze(X(:,idx_freq,:)),'alphadata',double(squeeze(Sv_f_per(:,idx_freq,:))>ax.CLim(1)));
        
        xlabel(ax,sprintf('%.1fkHz',f_vec(idx_freq)/1e3));
        
    case 'p'
        sl_min = get(src,'min');
        sl_max = get(src,'max');
        sl_val = get(src,'value');
        f_val = (sl_min + sl_max) - sl_val;
        
        [~,ip]=nanmin(abs(f_vec-f_val));
        
        set(hx,'Cdata',squeeze(Sv_f_per(ip,:,:)),'YData',squeeze(X(ip,:,:)),'alphadata',double(squeeze(Sv_f_per(ip,:,:))>ax.CLim(1)));
        ylabel(ax,sprintf('Ping Number %.0f',f_vec(ip)));
end

end
%
%
% function change_freq_cback(src,~,Sv_f,f_vec,im,ax)
%
% f_val=get(src,'value');
% [~,idx_freq]=nanmin(abs(f_vec/1e3-f_val));
%
% set(im,'Cdata',Sv_f(:,:,idx_freq)');
% title(ax,sprintf('%.0f kHz',f_vec(idx_freq)/1e3));
% set(im,'alphadata',double(Sv_f(:,:,idx_freq)'>ax.CLim(1)));
% grid(ax,'on');
%
% end