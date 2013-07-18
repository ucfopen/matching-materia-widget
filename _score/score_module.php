<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */
/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
 * @author      ADD NAME HERE
 */
namespace Materia;
class Score_Modules_Matching extends Score_Module
{
	
	/** @var unknown NEEDS DOCUMENTATION */
	public $is_case_sensitive;
	public function __construct($play_id, $inst)
	{
		parent::__construct($play_id, $inst);

		if (isset($inst->qset->data['options']['caseSensitive']) && $inst->qset->data['options']['caseSensitive'] == 1)
		{
			$this->is_case_sensitive = true;
		}
		else
		{
			$this->is_case_sensitive = false;
		}
	}
	/**
	 * NEEDS DOCUMENTATION
	 *
	 * @param unknown NEEDS DOCUMENTATION
	 */
	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$question = $this->questions[$log->item_id];
			// need to check if the qset allows for case sensitive answers
			$t1 = $log->text;
			$t2 = $question->answers[0]['text'];
			if ( ! $this->is_case_sensitive)
			{
				// we dont care about case, so just convert all to upper
				$t1 = strtoupper($t1);
				$t2 = strtoupper($t2);
			}
			if ($t1 == $t2)
			{
				return 100;
			}
		}

		return 0;
	}
}