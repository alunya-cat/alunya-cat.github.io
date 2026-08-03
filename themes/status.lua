-- status.lua
return {
    
    focus = "Pomodoro [██░░]",
    focus_icon = "🍅",
    
    msg = "LOG: Compilación estática finalizada con éxito.",
    
    -- Mon (1) / Tue (1+2) / Wed (1+2+3) / Thu (1) / Fri (1+2) / Sat (1) / Sun (1+2+3)
    -- Histórico de Pomodoros (Formato: "YYYY-MM-DD" = cantidad)
    pomodoros = {
        ["2026-07-05"] = 4,
        ["2026-07-06"] = 4,
        ["2026-07-13"] = 2,
        ["2026-07-14"] = 4
    }
}