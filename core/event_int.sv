

//Interface that contains all event signals
interface EVENT_INT;
    logic load;
    logic store;
    logic unaligned;
    logic arithmetic;
    logic trap;
    logic interrupt;
    logic conditional_branch;
    logic unconditional_branch;
    logic branch;
    logic execute;
    modport in
    (
        input load,
        input store,
        input unaligned,
        input arithmetic,
        input trap,
        input interrupt,
        input conditional_branch,
        input unconditional_branch,
        input branch,
        input execute
    );
    modport out
    (

        output load,
        output store,
        output unaligned,
        output arithmetic,
        output trap,
        output interrupt,
        output conditional_branch,
        output unconditional_branch,
        output branch,
        output execute
    );
endinterface //EVENT_INT