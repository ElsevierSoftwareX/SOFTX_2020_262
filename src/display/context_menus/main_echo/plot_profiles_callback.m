function plot_profiles_callback(~,~,main_figure)
layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
trans=trans_obj;

Bottom=trans.Bottom;

ax_main=axes_panel_comp.echo_obj.main_ax;


x_lim=double(get(ax_main,'xlim'));
y_lim=double(get(ax_main,'ylim'));


cp = ax_main.CurrentPoint;
x=cp(1,1);
y=cp(1,2);

x=nanmax(x,x_lim(1));
x=nanmin(x,x_lim(2));

y=nanmax(y,y_lim(1));
y=nanmin(y,y_lim(2));


xlab_str='Ping Number';
xdata=trans.get_transceiver_pings();

ydata=trans.get_transceiver_range();
[~,idx_ping]=nanmin(abs(xdata-x));
idx_r=ceil(y);

vert_val=trans.Data.get_subdatamat(1:length(ydata),idx_ping,'field',curr_disp.Fieldname);
horz_val=trans.Data.get_subdatamat(idx_r,1:length(xdata),'field',curr_disp.Fieldname);

switch lower(deblank(curr_disp.Fieldname))
    case{'alongangle','acrossangle'}
        ylab_str=sprintf('Angle(%c)',char(hex2dec('00BA')));
    case{'alongphi','acrossphi'}
        ylab_str=sprintf('Phase(%c)',char(hex2dec('00BA')));
    case 'power'
        ylab_str=sprintf('%s(dB)',curr_disp.Type);
        vert_val=pow2db_perso(vert_val);
        horz_val=pow2db_perso(horz_val);
    otherwise
        ylab_str=sprintf('%s(dB)',curr_disp.Type);
end


if ~isempty(Bottom.Sample_idx)
    if ~isnan(Bottom.Sample_idx(idx_ping))
        bot_val=ydata(Bottom.Sample_idx(idx_ping));
    else
        bot_val=nan;
    end
else
    bot_val=nan;
end

pos = getpixelposition(main_figure);

v_figure_size = [pos(1) pos(2) pos(4)/4 pos(4)];
h_figure_size = [pos(1) pos(2) pos(3) pos(3)/8];


v=new_echo_figure(main_figure,'Tag','profile_v','Toolbar','esp3','MenuBar','esp3','Units','','Position',v_figure_size);
axv=axes(v);
hold(axv,'on');
title(axv,sprintf('Vertical Profile for Ping: %.0f',idx_ping))
plot(axv,vert_val,ydata,'k');
hold(axv,'on');
yline(axv,bot_val,'r');
grid(axv,'on');
ylabel(axv,'Range(m)')
xlabel(axv,ylab_str);
axis(axv,'ij');


h=new_echo_figure(main_figure,'Tag','profile_h','Toolbar','esp3','MenuBar','esp3','Units','','Position',h_figure_size);
axh=axes(h);
hold(axh,'on');
title(axh,sprintf('Horizontal Profile for sample: %.0f, Range: %.2fm',idx_r,ydata(idx_r)))
plot(axh,xdata,horz_val,'r');
grid(axh,'on');

xlabel(axh,xlab_str);
ylabel(axh,ylab_str);








end