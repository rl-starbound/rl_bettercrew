local previous_init = init

function init()
  previous_init()

  message.setHandler("rl_bettercrew_playCrewCommunicationSound", function()
      animator.playSound("rl_bettercrew_crewCommunication")
    end)
end
