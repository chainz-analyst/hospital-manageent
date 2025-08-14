-- rank by specialization that generate much money
WITH together AS (
SELECT specialization, sum(amount) Revenue
FROM  billing bill
JOIN treatments t on t.treatment_id = bill.treatment_id
JOIN appointments app  on  t.appointment_id = app.appointment_id
JOIN doctors dr on app.doctor_id = dr.doctor_id
WHERE payment_status = 'paid'
GROUP BY specialization
),
overall as (
 SELECT sum(Revenue) as total 
 FROM together
 ) 
 SELECT specialization,Revenue,round((Revenue/total) * 100,2) PERCEENT, 
RANK() OVER(ORDER BY Revenue DESC)  `rank`
 FROM together 
 CROSS JOIN overall 
 ORDER BY Revenue DESC;
 
 -- doctor and specialization that generate muvh money
with rankover as  (
SELECT dr.first_name, dr.last_name,dr.specialization,  COUNT(DISTINCT app.appointment_id) TOTAL_APP, sum(amount) TOTAL_AMOUNT, 
round(avg(amount),2) average,dr.doctor_id
from billing bill
JOIN treatments treat ON bill.treatment_id = treat.treatment_id
JOIN appointments app ON treat.appointment_id = app.appointment_id
JOIN doctors dr ON app.doctor_id = dr.doctor_id 
WHERE payment_status = "PAID"
GROUP BY dr.first_name, dr.last_name,dr.specialization, dr.doctor_id
)
SELECT *,
RANK() OVER(PARTITION BY specialization ORDER BY average desc) as `rank`
from rankover;
 
 
 -- top 5 patient 
 WITH rev as (   SELECT pat.first_name, pat.last_name,sum(amount) total, pat.patient_id, count(app.appointment_id) appoint
FROM billing bill
JOIN treatments treat on bill.treatment_id = treat.treatment_id
JOIN appointments app on treat.appointment_id = app.appointment_id
join patients pat on app.patient_id = pat.patient_id
WHERE payment_status = "paid"
GROUP BY pat.patient_id, pat.first_name, pat.last_name
),
total_rev as (
SELECT sum(total) gtotal
from rev
)
 SELECT first_name,last_name, total, round((total/gtotal) *100,2) per, appoint,
 DENSE_RANK() OVER( ORDER BY total DESC) `rank`
 from rev 
 CROSS JOIN total_rev
 ORDER BY total  desc
 LIMIT 5;
 
 
-- top doctor in each department 
  with spec as  ( SELECT dr.first_name, dr.last_name, dr.doctor_id, dr.specialization, sum(amount) revenue
FROM billing bill
JOIN treatments treat on bill.treatment_id = treat.treatment_id
JOIN appointments app on treat.appointment_id = app.appointment_id
JOIN doctors dr ON app.doctor_id = dr.doctor_id
WHERE payment_status = 'paid'
GROUP BY dr.doctor_id,dr.first_name, dr.last_name,dr.specialization

),
grand as (
SELECT sum(revenue) total
FROM spec
)
SELECT first_name, last_name, doctor_id, specialization, revenue,round((revenue/total)*100,2) percentage,
RANK() OVER( ORDER BY revenue desc) ranky
FROM spec
CROSS JOIN grand
ORDER BY revenue desc
LIMIT 3
;
-- peak month
SELECT monthname(bill_date) mon, year(bill_date) yr  ,sum(amount) revenue
FROM billing
WHERE payment_status = 'paid'
GROUP BY mon, yr
ORDER BY revenue DESC
LIMIT 1
;

-- peak month in each branch
 with peak as (
 SELECT  hospital_branch,monthname(bill_date) mon, year(bill_date) yr  ,sum(amount) revenue
FROM billing bill 
JOIN treatments treat on bill.treatment_id = treat.treatment_id
JOIN  appointments app on treat.appointment_id = app.appointment_id
JOIN doctors dr ON app.doctor_id = dr.doctor_id
WHERE payment_status = 'paid'
GROUP BY hospital_branch, mon, yr
),
 branch as(
SELECT sum(revenue) total
FROM peak
),
lll as (
SELECT  hospital_branch, mon, yr,revenue
, round((revenue/total)*100,2) percent, RANK() OVER( PARTITION BY hospital_branch ORDER BY revenue DESC) `rank`
FROM peak
CROSS JOIN branch
)
SELECT *
FROM lll
WHERE `rank` <2
ORDER BY revenue DESC;


-- patient with appointmen number
with b4avg as (  SELECT pat.patient_id, pat.first_name, pat.last_name, count(appointment_id) appointment_no
FROM patients pat 
JOIN appointments app on pat.patient_id = app.patient_id
WHERE app.status = 'completed'
GROUP BY pat.patient_id, pat.first_name, pat.last_name
),
avge as ( 
SELECT sum(appointment_no) as total, count(DISTINCT patient_id) as coun
FROM b4avg
)
 SELECT first_name, last_name, appointment_no,
 total/coun averag
 from  b4avg
 CROSS JOIN avge
 ORDER BY appointment_no DESC;
 
 -- by  gender classification
 with b4avg as (  SELECT pat.gender, count(appointment_id) appointment_no, count(distinct pat.patient_id) as coun, sum(amount) revenue
FROM billing bill
JOIN patients pat on bill.patient_id = pat.patient_id
JOIN appointments app on pat.patient_id = app.patient_id
WHERE app.status = 'completed' and payment_status = 'paid'
GROUP BY pat.gender
)
 SELECT gender,appointment_no, coun, revenue,
 appointment_no/coun averag
 from  b4avg
 ORDER BY appointment_no DESC;
 
 --  by age gruop 
 SELECT CASE WHEN age BETWEEN 19 AND 34 THEN "Young Adult" 
WHEN age BETWEEN 35 AND 55 THEN "Adult"
ELSE "OLD" END as age_group,
count(appointment_id) appiontment_no, count(DISTINCT patient_id) patient_no, sum(amount) revenue
from (SELECT pat.patient_id,appointment_id, year(curdate()) -year(date_of_birth) age, amount
FROM billing bill
JOIN patients pat on bill.patient_id = pat.patient_id
JOIN appointments app on pat.patient_id = app.patient_id 
WHERE app.status = 'completed' and payment_status = 'paid'
) as grou
GROUP BY age_group
ORDER BY revenue DESC;

-- reason for visitaion 
WITH visit as (  SELECT reason_for_visit, count(appointment_id) num
FROM appointments
WHERE status = 'completed'
GROUP BY reason_for_visit

), 
 tvisit  as ( SELECT sum(num) total
 FROM visit
 )
 SELECT reason_for_visit, num,round((num/ total) *100, 2) percent
 FROM visit
 CROSS JOIN tvisit
 ORDER BY num DESC;
 
 -- treatment by visitation
 WITH stat as (  SELECT treatment_type, count(app.appointment_id) num
 FROM treatments treat 
 JOIN  appointments app on  treat.appointment_id = app.appointment_id
 WHERE status = 'completed'
 GROUP BY treatment_type
 ),
 totnum as (
 SELECT sum(num) total
 FROM stat
 )
 SELECT treatment_type, num,round((num/total)*100, 2) percent
 FROM stat
 CROSS JOIN totnum
 ORDER BY num DESC;
 
 -- treatment by revenue 
 WITH stat as (  SELECT treatment_type, count(app.appointment_id) num, sum(amount) rev
 FROM billing bill
 JOIN treatments treat on bill.treatment_id = treat.treatment_id
 JOIN  appointments app on  treat.appointment_id = app.appointment_id
 WHERE status = 'completed' AND payment_status = 'paid'
 GROUP BY treatment_type
 ),
 totnum as (
 SELECT sum(rev) total
 FROM stat
 )
 SELECT treatment_type,rev ,round((rev/total)*100, 2) percent
 FROM stat
 CROSS JOIN totnum
 ORDER BY rev DESC;
 
 -- avg treatment cost
 
 WITH stat as (  SELECT treatment_type, count(app.appointment_id) num, sum(amount) rev, round(avg(cost), 2) avge 
 FROM billing bill
 JOIN treatments treat on bill.treatment_id = treat.treatment_id
 JOIN  appointments app on  treat.appointment_id = app.appointment_id
 WHERE status = 'completed' AND payment_status = 'paid'
 GROUP BY treatment_type
 ),
 totnum as (
 SELECT sum(rev) total
 FROM stat
 )
 SELECT treatment_type,rev , avge, round((rev/total)*100, 2) percent
 FROM stat
 CROSS JOIN totnum
 ORDER BY rev DESC;
 
 -- revenue vs number off appontment per branch
 WITH branzh as (  SELECT hospital_branch, sum(amount) revenue , count(app.appointment_id) num
FROM billing bill
JOIN treatments treat on bill.treatment_id = treat.treatment_id
JOIN appointments app on treat.appointment_id = app.appointment_id
JOIN doctors dr on app.doctor_id = dr.doctor_id
WHERE payment_status = 'paid' and app.status = 'completed'
GROUP BY hospital_branch),
branch as (
SELECT sum(revenue) as rev, sum(num) as appoint
FROM branzh   
)
SELECT hospital_branch, revenue, num, round((revenue/rev)*100, 2) rev_percent, round((num/appoint)*100,2) app_percent
FROM branzh
CROSS JOIN branch
;