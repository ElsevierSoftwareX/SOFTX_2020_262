function state=get_figure_state(fig)
state=true;
if isempty(fig)
    return;
end
jFigPeer = get(handle(fig),'JavaFrame');
jWin=jFigPeer.fHG2Client.getWindow;
state=jWin.isEnabled;

end