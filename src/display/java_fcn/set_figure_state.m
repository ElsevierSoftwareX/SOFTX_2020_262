function set_figure_state(fig,state)
if isempty(fig)
    return;
end
jFigPeer = get(handle(fig),'JavaFrame');
jWin=jFigPeer.fHG2Client.getWindow;
jWin.setEnabled(state);
if ~isdeployed()
    if state
        disp('Enabling');
    else
        disp('Disabling');
    end
end

end