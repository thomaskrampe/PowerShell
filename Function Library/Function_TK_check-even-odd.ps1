Function TK_check-even-odd ($num) {[bool]!($num%2)}

# Example script using the function above
$Computers = "LAB5003XA01", "LAB5003XA02", "LAB5003XA03", "LAB5003XA04", "LAB5003XA05"

foreach ($computer in $computers) {
    if ($computer -like "LAB5003XA*") {
        [int]$ComputerNum = $computer.Substring($computer.Length - 2)
        
        if((TK_check-even-odd $computerNum) -eq $true) {
            #even hostname ending
            "Do something for even computer: {0}" -f $computer
        }
        else {
            #odd hostname ending
            "Do something for odd computer: {0}" -f $computer
        }
    }
    else {
        "Computer does not meet naming standards:  {0}" -f $computer
    }
}
