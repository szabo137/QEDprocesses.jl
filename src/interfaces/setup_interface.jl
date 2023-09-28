###############
# The process setup 
#
# In this file, we define the interface for general computation and process setups.
###############

"""
Abstract base type for computation setups.  A *setup* means
a collection of setup data needed to evaluate a dedicated quantity of given
running data. Therefore, each setup is associated with a single quantity, which one may compute using the setup data and the running data. 
Despite that, the decomposition into setup and running data is
arbitrary, and this can be used for cases where a subset of the variables a
quantity depends on is kept constant. 

!!! note "Computation setup interface"
    
    The computation performed using a computation setup is separated into three steps:
        
        1. input validation
        2. actual computation
        3. post processing

    where every step has its own interface function (see [`compute`](@ref) for details). 
    
    ## Input validation

    Every subtype of `AbstractComputationSetup` should implement the interface function
    
    ```Julia
    _is_valid_input(stp::AbstractComputationSetup, input) # default: true
    ```
    
    which should return true iff the `input` is valid for the computation of the associated quantity (see [`_is_valid_input`](@ref) and [`_assert_valid_input`](@ref) for more details). 
    The default implementation always returns `true`. Provide a custom implementation if a different behavior is required.

    ## Actual computation
    
    Every subtype of `AbstractComputationSetup` must at least implement the required interface function
    
    ```Julia
    _compute(stp::AbstractComputationSetup, input) 
    ```
    
    which computes the value of the associated quantity for a given `input` (see [`_compute`](@ref) for more details).


    ## Post computation

    Every subtype of `AbstractComputationSetup` should implement the interface function
    
    ```Julia
    _post_computation(stp::AbstractComputationSetup, input) 
    ```
    
    which performs *computations* after the actual computation, e.g. conversions or normalizations (see [`_post_computation`](@ref) for more details).


    
"""
abstract type AbstractComputationSetup end

# convenience function to check if an object is a computation setup
_is_computation_setup(::AbstractComputationSetup) = true

"""

    _is_valid_input(stp::AbstractComputationSetup, input::Any)

Interface function, which returns true if the constraints of the `input` associated with the quantity of `stp` are met.
This function is called to validate the input of [`compute`](@ref) before calling [`_compute`](@ref).

!!! note "Default implementation"
    
    Since no input validation is equivalent to every input being valid, this function returns `true` by default. 
    This behavior can be overwritten if actual validation is necessary.


An assert version of this function is given by [`_assert_valid_input`](@ref), which directly uses the output of this function.

"""
@inline function _is_valid_input(stp::AbstractComputationSetup, input)
    return true
end
"""

    InvalidInputError(msg::String)

Exception which is thrown if a given input is invalid, e.g. passed to [`_assert_valid_input`](@ref).
"""
struct InvalidInputError <: Exception
    msg::String
end
Base.showerror(io::IO, err::InvalidInputError) = println(io, "InvalidInputError: $(err.msg).")

"""

    _assert_valid_input(stp::AbstractComputationSetup, input::Any)

Interface function, which asserts that the given `input` is valid, and throws an [`InvalidInputError`](@ref) if not.

!!! note "default implementation"

    The generic fallback uses the boolian value returned by `_is_valid_input(stp,input)` to check for validity, 
    i.e. if the returned value is `true` the assert does not trigger and nothing happens, but if the returned value is `false`, 
    an error with a generic error message will be thrown (see  [`_is_valid_input`](@ref) for details). 
    To customize the error message, or use a custom assertion mechanism, just add your own implementation of

    ```Julia
    _assert_valid_input(stp::YourCustomSetup,input)
    ```
    which should throw an [`InvalidInputError`](@ref) if the input is invalid.
    Despite the presence of a custom `_assert_valid_input`, it is highly recommended to also implement `_is_valid_input` for `CustomSetup`, because it might be used outside of the assert function.

"""
@inline function _assert_valid_input(stp::AbstractComputationSetup,input)
    _is_valid_input(stp,input) || throw(InvalidInputError("Something wrong with the input!\n setup:$stp \n input:$input"))

    return nothing
end

"""
    
    function _post_computation(stp::AbstractComputationSetup, input::Any, result::Any)
    
Interface function, which is called in [`compute`](@ref) after [`_compute`](@ref) has been called. This function is dedicated to 
finalize the result of a computation. 

!!! note "default implementation"

    Since in the case of no post computation the result of [`_compute`](@ref) is unchanged, this function returns `result` by default.

"""
@inline function _post_computation(stp::AbstractComputationSetup, input, result)
    return result
end

"""
    
    _compute(stp::AbstractComputationSetup, input::Any)

Interface function that returns the value of the associated quantity evaluated on `input`, which can be anything the associated quantity is defined to be feasible for.

!!! note "unsafe implementation"

    This function must be implemented for any subtype of [`AbstractComputationSetup`]. It should not do any input validation or post processing (see [`_is_valid_input`](@ref) and [`_post_computation`](@ref)), as those two are performed while calling 
    the safe version of this function [`compute`](@ref).

"""
function _compute end

"""

    compute(stp::AbstractComputationSetup, input::Any)

Return the value of the quantity associated with `stp` for a given `input`. 
In addition to the actual call of the associated unsafe version [`_compute`](@ref),
input validation ([`_assert_valid_input`]) and post computation
(using [`_post_computation`](@ref)) are wrapped around the calculation (see [`AbstractComputationSetup`](@ref) for details).
"""
function compute(stp::AbstractComputationSetup, input)
    _assert_valid_input(stp,input) 
    raw_result = _compute(stp,input)
    return _post_computation(stp, input,raw_result)
end

"""
Abstract base type for setups related to combining scattering processes and compute models.  
Every subtype of `AbstractProcessSetup` must implement at least the following 
interface functions:

```Julia
scattering_process(::AbstractProcessSetup) 
compute_model(::AbstractProcessSetup) 
```

Derived from these interface functions, the following delegations are provided:

```Julia
number_incoming_particles(::AbstractProcessSetup)
number_outgoing_particles(::AbstractProcessSetup)
```

"""
abstract type AbstractProcessSetup <: AbstractComputationSetup end

"""
    
    scattering_process(stp::AbstractProcessSetup)

Interface function that returns the scattering process associated with `stp`,
i.e. an object which is a subtype of `AbstractProcessDefinition`. 
"""
function scattering_process end

"""

    compute_model(stp::AbstractProcessSetup)

Interface function that returns the compute model associated with `stp`, i.e.
an object which is a subtype of `AbstractModelDefinition`.
"""
function compute_model end

@inline number_incoming_particles(stp::AbstractProcessSetup) = number_incoming_particles(scattering_process(stp))
@inline number_outgoing_particles(stp::AbstractProcessSetup) = number_outgoing_particles(scattering_process(stp))

